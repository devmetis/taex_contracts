// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ITaexNFT {
    function primaryPrice() external view returns (uint256);
    function isListedForSale(uint256) external view returns (bool);
    function tokenPrice(uint256) external view returns (uint256);
    function ownerOfToken(uint256) external view returns (address);
    function mint(address) external returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract SaleNFT is Ownable, ReentrancyGuard {
    uint256 public feeSecondarySale; // decimals 2 ex: if want to set as 1.5% then 150

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
    event PrimarySaleByAdmin(
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
        uint256 _feeSecondarySale
    ) isNotZero(_feeSecondarySale) Ownable(msg.sender) {
        feeSecondarySale = _feeSecondarySale;
    }

    function primarySale(
        address _taexNFT
    ) external payable isNotZeroAddress(_taexNFT) returns (uint256) {
        uint256 price = ITaexNFT(_taexNFT).primaryPrice();

        // Ensure the sent amount is at least the price
        require(msg.value >= price, "SaleNFT: Insufficient Amount to sale NFT");

        // Mint the NFT to the sender
        uint256 newTokenId = ITaexNFT(_taexNFT).mint(msg.sender);

        // If the buyer sent more than the price, refund the excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        emit PrimarySale(_taexNFT, newTokenId, msg.sender);
        return newTokenId;
    }

    function primarySaleByAdmin(
        address _taexNFT,
        address to
    )
        external
        onlyOwner
        isNotZeroAddress(_taexNFT)
        isNotZeroAddress(to)
        returns (uint256)
    {
        uint256 newTokenId = ITaexNFT(_taexNFT).mint(to);
        emit PrimarySaleByAdmin(_taexNFT, newTokenId, to);
        return newTokenId;
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

        // Calculate the sale fee
        uint256 feeAmount = (price * feeSecondarySale) / 10000;

        // Transfer fee to the contract
        require(
            address(this).balance >= feeAmount,
            "Contract has insufficient balance for fee"
        );

        // Transfer the remaining amount to the seller (owner of the NFT)
        (bool successOwner, ) = payable(owner).call{value: price - feeAmount}(
            ""
        );
        require(successOwner, "SaleNFT: Failed to transfer ETH to owner ");

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
     * @dev External function to set primary price only by admin
     */
    function setFeeSecondarySale(
        uint256 _feePercentage
    ) external isNotZero(_feePercentage) onlyOwner {
        feeSecondarySale = _feePercentage;
    }
}
