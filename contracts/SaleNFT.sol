// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ITaexNFT {
    function isListedForSale(uint256) external view returns (bool);
    function tokenPrice(uint256) external view returns (uint256);
    function ownerOfToken(uint256) external view returns (address);
    function tokenPrimaryArtistFee(uint256) external view returns (uint256);
    function tokenSecondaryArtistFee(uint256) external view returns (uint256);
    function tokenSecondaryTaexFee(uint256) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract SaleNFT is Ownable, ReentrancyGuard {
    address public artistTreasury;
    address public taexTreasury;

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "SaleNFT: zero address");
        _;
    }

    modifier isNotZero(uint256 amount) {
        require(amount > 0, "SaleNFT: zero amount");
        _;
    }
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

    constructor(
        address _artistTreasury,
        address _taexTreasury
    ) isNotZeroAddress(_artistTreasury) isNotZeroAddress(_taexTreasury) Ownable(msg.sender) {
        artistTreasury = _artistTreasury;
        taexTreasury = _taexTreasury;
    }

    function primarySale(
        address _taexNFT,
        uint256 _tokenId
    ) external payable nonReentrant isNotZeroAddress(_taexNFT) {
        // Retrieve the token price
        uint256 price = ITaexNFT(_taexNFT).tokenPrice(_tokenId);
        address owner = ITaexNFT(_taexNFT).ownerOfToken(_tokenId);
        // Check that the token has an owner
        require(owner != address(0), "SaleNFT: zero address");

        uint256 primaryArtistFee = ITaexNFT(_taexNFT).tokenPrimaryArtistFee(
            _tokenId
        );

        // Ensure the sent amount is at least the price
        require(msg.value >= price, "SaleNFT: Insufficient Amount to sale NFT");

        // Calculate the sale fee
        uint256 primaryArtistFeeAmount = (price * primaryArtistFee) / 100;

        (bool successArtist, ) = payable(artistTreasury).call{
            value: primaryArtistFeeAmount
        }("");
        require(
            successArtist,
            "SaleNFT: Failed to transfer ETH to artist treasury"
        );
        (bool successTaex, ) = payable(taexTreasury).call{
            value: price - primaryArtistFeeAmount
        }("");
        require(
            successTaex,
            "SaleNFT: Failed to transfer ETH to Taex treasury"
        );

        // Transfer the NFT to the buyer
        ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId);

        // If the buyer sent more than the price, refund the excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        emit PrimarySale(_taexNFT, _tokenId, msg.sender);
    }

    function secondarySale(
        address _taexNFT,
        uint256 _tokenId
    ) external payable nonReentrant isNotZeroAddress(_taexNFT) {
        address owner = ITaexNFT(_taexNFT).ownerOfToken(_tokenId);

        // Check that the token has an owner
        require(owner != address(0), "SaleNFT: zero address");

        // Ensure the token is listed for sale
        bool isListed = ITaexNFT(_taexNFT).isListedForSale(_tokenId);
        require(isListed, "SaleNFT: Not listed for sale");

        // Retrieve the token price
        uint256 price = ITaexNFT(_taexNFT).tokenPrice(_tokenId);

        // Ensure the buyer has sent enough ETH
        require(msg.value >= price, "SaleNFT: Insufficient Amount to buy NFT");

        uint256 secondaryArtistFee = ITaexNFT(_taexNFT).tokenSecondaryArtistFee(
            _tokenId
        );
        uint256 secondaryTaexFee = ITaexNFT(_taexNFT).tokenSecondaryTaexFee(
            _tokenId
        );
        // Calculate the sale fee
        uint256 secondaryArtistFeeAmount = (price * secondaryArtistFee) / 100;
        uint256 secondaryTaexFeeAmount = (price * secondaryTaexFee) / 100;

        // Transfer the remaining amount to the seller (owner of the NFT)
        (bool successOwner, ) = payable(owner).call{
            value: price - secondaryArtistFeeAmount - secondaryTaexFeeAmount
        }("");
        require(successOwner, "SaleNFT: Failed to transfer ETH to owner ");

        (bool successArtist, ) = payable(artistTreasury).call{
            value: secondaryArtistFeeAmount
        }("");
        require(
            successArtist,
            "SaleNFT: Failed to transfer ETH to artist treasury"
        );

        (bool successTaex, ) = payable(taexTreasury).call{
            value: secondaryTaexFeeAmount
        }("");
        require(
            successTaex,
            "SaleNFT: Failed to transfer ETH to Taex treasury"
        );

        // Transfer the NFT to the buyer
        ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId);

        // If the buyer sent more than the price, refund the excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit SecondarySale(_taexNFT, _tokenId, msg.sender);
    }

    function withdrawETH(address to) external onlyOwner isNotZeroAddress(to) {
        uint256 balance = address(this).balance;
        require(balance > 0, "SaleNFT: No ETH to withdraw");

        (bool success, ) = payable(to).call{value: balance}("");
        require(success, "SaleNFT: Withdraw rejected ETH transfer");

        emit ETHWithdrawn(to, balance);
    }

    /**
     * @dev External function to set artist treasury address only by admin
     */
    function setArtistTreasury(
        address _artistTreasury
    ) external isNotZeroAddress(_artistTreasury) onlyOwner {
        artistTreasury = _artistTreasury;
    }
    /**
     * @dev External function to set Taex treasury address only by admin
     */
    function setTaexTreasury(
        address _taexTreasury
    ) external isNotZeroAddress(_taexTreasury) onlyOwner {
        taexTreasury = _taexTreasury;
    }
}
