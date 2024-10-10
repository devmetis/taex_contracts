// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TaexNFT is ERC721, Ownable, ReentrancyGuard {
    uint256 private _lastTokenId;

    string public internalBaseURI;
    mapping(uint256 => bool) public isListedForSale;
    mapping(uint256 => uint256) public tokenPrice;
    uint256 public primaryPrice;

    uint256 public primaryArtistFee;
    uint256 public secondaryArtistFee;
    uint256 public secondaryTaexFee;

    mapping(uint256 => uint256) public tokenPrimaryArtistFee;
    mapping(uint256 => uint256) public tokenSecondaryArtistFee;
    mapping(uint256 => uint256) public tokenSecondaryTaexFee;

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "TaexNFT: zero address");
        _;
    }

    modifier isNotZero(uint256 amount) {
        require(amount > 0, "TaexNFT: zero amount");
        _;
    }

    event TokenListedForSale(uint256 indexed tokenId, uint256 price);
    event TokenUnListedForSale(uint256 indexed tokenId);
    event TokenPriceAdjusted(uint256 indexed tokenId, uint256 price);
    event TokenMinted(address indexed to, uint256 tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _primaryPrice,
        uint256 _primaryArtistFee,
        uint256 _secondaryArtistFee,
        uint256 _secondaryTaexFee
    ) isNotZero(_primaryPrice) ERC721(_name, _symbol) Ownable(msg.sender) {
        internalBaseURI = _uri;
        primaryPrice = _primaryPrice;
        primaryArtistFee = _primaryArtistFee;
        secondaryArtistFee = _secondaryArtistFee;
        secondaryTaexFee = _secondaryTaexFee;
    }

    function ownerOfToken(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @dev External function to list NFT for sale by token's owner
     */
    function listForSale(uint256 _tokenId, uint256 _price) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "TaexNFT:caller is not owner of tokenId"
        );
        isListedForSale[_tokenId] = true;
        tokenPrice[_tokenId] = _price;

        emit TokenListedForSale(_tokenId, _price);
    }

    function unlistFromSale(uint256 _tokenId) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "TaexNFT:caller is not owner of tokenId"
        );
        isListedForSale[_tokenId] = false;
        emit TokenUnListedForSale(_tokenId);
    }

    /**
     * @dev External function to change NFT price by token's owner
     */
    function adjustPrice(uint256 _tokenId, uint256 _price) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "TaexNFT:caller is not owner of tokenId"
        );
        tokenPrice[_tokenId] = _price;
        emit TokenPriceAdjusted(_tokenId, _price);
    }

    /**
     * @dev External function to set new Base URI only by admin
     */
    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        internalBaseURI = newBaseUri;
    }

    /**
     * @dev External function to set primary price only by admin
     */
    function setPrimaryPrice(
        uint256 _price
    ) external isNotZero(_price) onlyOwner {
        primaryPrice = _price;
    }

    function mint(
        address to
    ) external onlyOwner nonReentrant isNotZeroAddress(to) returns (uint256) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        tokenPrice[tokenId] = primaryPrice;
        tokenPrimaryArtistFee[tokenId] = primaryArtistFee;
        tokenSecondaryArtistFee[tokenId] = secondaryArtistFee;
        tokenSecondaryTaexFee[tokenId] = secondaryTaexFee;
        _safeMint(to, tokenId);
        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    function mintWithSpecifiedFee(
        address to,
        uint256 _primaryArtistFee,
        uint256 _secondaryArtistFee,
        uint256 _secondaryTaexFee
    ) external onlyOwner nonReentrant isNotZeroAddress(to) returns (uint256) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        tokenPrice[tokenId] = primaryPrice;
        tokenPrimaryArtistFee[tokenId] = _primaryArtistFee;
        tokenSecondaryArtistFee[tokenId] = _secondaryArtistFee;
        tokenSecondaryTaexFee[tokenId] = _secondaryTaexFee;
        _safeMint(to, tokenId);
        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return internalBaseURI;
    }
}
