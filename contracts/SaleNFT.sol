// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ITaexNFT {
    /**
     * @notice Retrieve the data of a token.
     * @param tokenId The ID of the token to retrieve data for.
     * @return isListedForSale Whether the token is listed for sale.
     * @return primaryArtistFee The fee for the artist during the primary sale.
     * @return secondaryArtistFee The fee for the artist during the secondary sale.
     * @return secondaryTaexFee The fee for the Taex treasury during the secondary sale.
     * @return price The price of the token.
     */
    function tokenData(
        uint256 tokenId
    )
        external
        view
        returns (
            bool isListedForSale,
            uint8 primaryArtistFee,
            uint8 secondaryArtistFee,
            uint8 secondaryTaexFee,
            uint256 price
        );

    /**
     * @notice Retrieve the owner of a token.
     * @param tokenId The ID of the token.
     * @return The address of the token owner.
     */
    function ownerOfToken(uint256 tokenId) external view returns (address);

    /**
     * @notice Transfer a token from one address to another.
     * @param from The address to transfer the token from.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title SaleNFT Contract
 * @notice This contract manages the primary and secondary sales of NFTs.
 */
contract SaleNFT is Ownable2Step, ReentrancyGuard {
    address public artistTreasury;
    address public taexTreasury;
    mapping(address => bool) public whitelist;

    /**
     * @notice Emitted when a primary sale occurs.
     * @param nft The address of the NFT contract.
     * @param tokenId The ID of the token sold.
     * @param to The address of the buyer.
     */
    event PrimarySale(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed to
    );

    /**
     * @notice Emitted when a secondary sale occurs.
     * @param nft The address of the NFT contract.
     * @param tokenId The ID of the token sold.
     * @param to The address of the buyer.
     */
    event SecondarySale(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed to
    );

    /**
     * @notice Emitted when ETH is withdrawn from the contract.
     * @param to The address to which the ETH is withdrawn.
     * @param amount The amount of ETH withdrawn.
     */
    event ETHWithdrawn(address indexed to, uint256 amount);

    /**
     * @notice Emitted when the artist treasury address is set.
     * @param treasury The address of the artist treasury.
     */
    event SetArtistTreasury(address indexed treasury);

    /**
     * @notice Emitted when the Taex treasury address is set.
     * @param treasury The address of the Taex treasury.
     */
    event SetTaexTreasury(address indexed treasury);

    /**
     * @notice Emitted when an NFT contract is added to the whitelist.
     * @param nftContract The address of the NFT contract.
     */
    event AddToWhitelist(address indexed nftContract);

    /**
     * @notice Emitted when an NFT contract is removed from the whitelist.
     * @param nftContract The address of the NFT contract.
     */
    event RemoveFromWhitelist(address indexed nftContract);

    error InvalidTokenId();
    error ZeroAmount();
    error InsufficientAmount();
    error TransferNFTFailed();
    error TransferETHToArtistFailed();
    error TransferETHToTaexFailed();
    error TransferETHToOwnerFailed();
    error TransferETHToWithdrawFailed();
    error NotListedForSale();
    error NoExistETHTowithdraw();
    error NotWhitelistedNFT();

    modifier onlyWhitelisted(address _taexNFT) {
        if (!whitelist[_taexNFT]) revert NotWhitelistedNFT();
        _;
    }

    modifier isNotZero(uint256 _amount) {
        if (_amount == 0) revert ZeroAmount();
        _;
    }

    /**
     * @notice Initializes the contract with artist and Taex treasury addresses.
     * @param _artistTreasury The address of the artist treasury.
     * @param _taexTreasury The address of the Taex treasury.
     */
    constructor(
        address _artistTreasury,
        address _taexTreasury
    ) Ownable2Step() {
        artistTreasury = _artistTreasury;
        taexTreasury = _taexTreasury;
    }

    /**
     * @notice Executes the primary sale of an NFT.
     * @param _taexNFT The address of the NFT contract.
     * @param _tokenId The ID of the token to be sold.
     */
    function primarySale(
        address _taexNFT,
        uint256 _tokenId
    ) external payable nonReentrant onlyWhitelisted(_taexNFT) {
        // Retrieve token data
        (, uint8 primaryArtistFee, , , uint256 price) = ITaexNFT(_taexNFT)
            .tokenData(_tokenId);
        address owner = ITaexNFT(_taexNFT).ownerOfToken(_tokenId);

        if (owner == address(0)) revert InvalidTokenId(); // Validate owner
        if (msg.value < price) revert InsufficientAmount(); // Validate payment

        // Transfer NFT to buyer
        ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId);

        if (ITaexNFT(_taexNFT).ownerOfToken(_tokenId) != msg.sender) {
            revert TransferNFTFailed();
        }

        // Calculate fees
        uint256 artistFeeAmount = (price * primaryArtistFee) / 100;

        // Pay artist treasury
        if (artistFeeAmount > 0) {
            (bool successArtist, ) = payable(artistTreasury).call{
                value: artistFeeAmount
            }("");
            if (!successArtist) revert TransferETHToArtistFailed();
        }

        // Pay Taex treasury
        (bool successTaex, ) = payable(taexTreasury).call{
            value: price - artistFeeAmount
        }("");
        if (!successTaex) revert TransferETHToTaexFailed();

        // Refund excess ETH if sent more than required
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit PrimarySale(_taexNFT, _tokenId, msg.sender);
    }

    /**
     * @notice Executes the secondary sale of an NFT.
     * @param _taexNFT The address of the NFT contract.
     * @param _tokenId The ID of the token to be sold.
     */
    function secondarySale(
        address _taexNFT,
        uint256 _tokenId
    ) external payable nonReentrant onlyWhitelisted(_taexNFT) {
        // Retrieve token data
        (
            bool isListed,
            ,
            uint8 secondaryArtistFee,
            uint8 secondaryTaexFee,
            uint256 price
        ) = ITaexNFT(_taexNFT).tokenData(_tokenId);
        address owner = ITaexNFT(_taexNFT).ownerOfToken(_tokenId);

        if (owner == address(0)) revert InvalidTokenId(); // Validate owner
        if (!isListed) revert NotListedForSale(); // Ensure token is listed for sale
        if (msg.value < price) revert InsufficientAmount(); // Validate payment

        // Transfer NFT to buyer
        ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId);

        if (ITaexNFT(_taexNFT).ownerOfToken(_tokenId) != msg.sender) {
            revert TransferNFTFailed();
        }

        // Calculate fees
        uint256 artistFeeAmount = (price * secondaryArtistFee) / 100;
        uint256 taexFeeAmount = (price * secondaryTaexFee) / 100;

        // Pay seller (owner)
        (bool successOwner, ) = payable(owner).call{
            value: price - artistFeeAmount - taexFeeAmount
        }("");
        if (!successOwner) revert TransferETHToOwnerFailed();

        // Pay artist treasury
        if (artistFeeAmount > 0) {
            (bool successArtist, ) = payable(artistTreasury).call{
                value: artistFeeAmount
            }("");
            if (!successArtist) revert TransferETHToArtistFailed();
        }

        // Pay Taex treasury
        if (taexFeeAmount > 0) {
            (bool successTaex, ) = payable(taexTreasury).call{
                value: taexFeeAmount
            }("");
            if (!successTaex) revert TransferETHToTaexFailed();
        }

        // Refund excess ETH if sent more than required
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit SecondarySale(_taexNFT, _tokenId, msg.sender);
    }

    /**
     * @notice Withdraws all ETH from the contract to a specified address.
     * @param to The address to withdraw ETH to.
     */
    function withdrawETH(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoExistETHTowithdraw();

        (bool success, ) = payable(to).call{value: balance}("");
        if (!success) revert TransferETHToWithdrawFailed();

        emit ETHWithdrawn(to, balance);
    }

    /**
     * @notice Sets the artist treasury address.
     * @param _artistTreasury The new address of the artist treasury.
     */
    function setArtistTreasury(address _artistTreasury) external onlyOwner {
        artistTreasury = _artistTreasury;
        emit SetArtistTreasury(_artistTreasury);
    }

    /**
     * @notice Sets the Taex treasury address.
     * @param _taexTreasury The new address of the Taex treasury.
     */
    function setTaexTreasury(address _taexTreasury) external onlyOwner {
        taexTreasury = _taexTreasury;
        emit SetTaexTreasury(_taexTreasury);
    }

    /**
     * @notice Adds an NFT contract to the whitelist.
     * @param _contract The address of the NFT contract to add.
     */
    function addToWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = true;
        emit AddToWhitelist(_contract);
    }

    /**
     * @notice Removes an NFT contract from the whitelist.
     * @param _contract The address of the NFT contract to remove.
     */
    function removeFromWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = false;
        emit RemoveFromWhitelist(_contract);
    }
}
