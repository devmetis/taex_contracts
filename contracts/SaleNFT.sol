// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ITaexNFT} from "./interfaces/ITaexNFT.sol";

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
    error InsufficientAmount();
    error TransferFailed();
    error NotListedForSale();
    error NoFundsToWithdraw();
    error NotWhitelistedNFT();

    modifier onlyWhitelisted(address _taexNFT) {
        require(whitelist[_taexNFT], "Not whitelisted");
        _;
    }

    constructor(
        address _artistTreasury,
        address _taexTreasury
    ) Ownable(msg.sender) {
        artistTreasury = _artistTreasury;
        taexTreasury = _taexTreasury;
    }

    function primarySale(
        address _taexNFT,
        uint256 _tokenId
    ) external payable nonReentrant onlyWhitelisted(_taexNFT) {
        (, uint8 primaryArtistFee, , , uint256 price) = ITaexNFT(_taexNFT)
            .tokenData(_tokenId);
        address owner = ITaexNFT(_taexNFT).ownerOfToken(_tokenId);

        if (owner == address(0)) revert InvalidTokenId();
        if (msg.value < price) revert InsufficientAmount();

        ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId);

        uint256 artistFeeAmount = (price * primaryArtistFee) / 100;

        _safeTransferETH(artistTreasury, artistFeeAmount);
        _safeTransferETH(taexTreasury, price - artistFeeAmount);

        if (msg.value > price) {
            _safeTransferETH(msg.sender, msg.value - price);
        }

        emit PrimarySale(_taexNFT, _tokenId, msg.sender);
    }

    function secondarySale(
        address _taexNFT,
        uint256 _tokenId
    ) external payable nonReentrant onlyWhitelisted(_taexNFT) {
        (
            bool isListed,
            ,
            uint8 secondaryArtistFee,
            uint8 secondaryTaexFee,
            uint256 price
        ) = ITaexNFT(_taexNFT).tokenData(_tokenId);
        address owner = ITaexNFT(_taexNFT).ownerOfToken(_tokenId);

        if (owner == address(0)) revert InvalidTokenId();
        if (!isListed) revert NotListedForSale();
        if (msg.value < price) revert InsufficientAmount();

        ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId);

        uint256 artistFeeAmount = (price * secondaryArtistFee) / 100;
        uint256 taexFeeAmount = (price * secondaryTaexFee) / 100;

        _safeTransferETH(owner, price - artistFeeAmount - taexFeeAmount);
        _safeTransferETH(artistTreasury, artistFeeAmount);
        _safeTransferETH(taexTreasury, taexFeeAmount);

        if (msg.value > price) {
            _safeTransferETH(msg.sender, msg.value - price);
        }

        emit SecondarySale(_taexNFT, _tokenId, msg.sender);
    }

    function withdrawETH(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsToWithdraw();

        _safeTransferETH(to, balance);

        emit ETHWithdrawn(to, balance);
    }

    function setArtistTreasury(address _artistTreasury) external onlyOwner {
        artistTreasury = _artistTreasury;
        emit SetArtistTreasury(_artistTreasury);
    }

    function setTaexTreasury(address _taexTreasury) external onlyOwner {
        taexTreasury = _taexTreasury;
        emit SetTaexTreasury(_taexTreasury);
    }

    function addToWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = true;
        emit AddToWhitelist(_contract);
    }

    function removeFromWhitelist(address _contract) external onlyOwner {
        whitelist[_contract] = false;
        emit RemoveFromWhitelist(_contract);
    }

    function _safeTransferETH(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
