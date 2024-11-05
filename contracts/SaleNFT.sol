// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Ensure you're using the latest compatible version

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ITaexNFT} from "./interfaces/ITaexNFT.sol";

/**
 * @title SaleNFT
 * @dev Contract for handling the sale of NFTs, including primary and secondary sales.
 */
contract SaleNFT is Ownable, ReentrancyGuard {
    address public artistTreasury;
    address public taexTreasury;
    mapping(address => bool) public whitelist;

    event PrimarySale(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed to
    );
    event SecondarySale(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed to
    );
    event ETHWithdrawn(address indexed to, uint256 amount);
    event SetArtistTreasury(address indexed treasury);
    event SetTaexTreasury(address indexed treasury);
    event AddToWhitelist(address indexed nftContract);
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

    constructor(
        address _artistTreasury,
        address _taexTreasury
    ) Ownable(msg.sender) {
        artistTreasury = _artistTreasury;
        taexTreasury = _taexTreasury;
    }

    /**
     * @dev Executes the primary sale of an NFT.
     * @param _taexNFT The address of the NFT contract.
     * @param _tokenId The ID of the token being sold.
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
     * @dev Executes the secondary sale of an NFT.
     * @param _taexNFT The address of the NFT contract.
     * @param _tokenId The ID of the token being sold.
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
     * @dev Withdraws ETH from the contract to a specified address.
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
     * @dev Sets the artist treasury address.
     * @param _artistTreasury The new artist treasury address.
     */
    function setArtistTreasury(address _artistTreasury) external onlyOwner {
        artistTreasury = _artistTreasury;
        emit SetArtistTreasury(_artistTreasury);
    }

    /**
     * @dev Sets the Taex treasury address.
     * @param _taexTreasury The new Taex treasury address.
     */
    function setTaexTreasury(address _taexTreasury) external onlyOwner {
        taexTreasury = _taexTreasury;
        emit SetTaexTreasury(_taexTreasury);
    }

    /**
     * @dev Adds a contract address to the whitelist.
     * @param _contract The address of the contract to whitelist.
     */
    function addToWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = true;
        emit AddToWhitelist(_contract);
    }

    /**
     * @dev Removes a contract address from the whitelist.
     * @param _contract The address of the contract to remove from the whitelist.
     */
    function removeFromWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = false;
        emit RemoveFromWhitelist(_contract);
    }
}
