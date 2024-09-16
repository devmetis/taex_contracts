// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TaexNFT is ERC721, Ownable, ReentrancyGuard {
    uint256 private _lastTokenId;

    string public internalBaseURI;
    address public minter;
    mapping(uint256 => bool) public isListedForSale;
    mapping(uint256 => uint256) public tokenPrice;
    uint256 public primaryPrice;

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "TaexNFT: zero address");
        _;
    }

    modifier isNotZero(uint256 amount) {
        require(amount > 0, "TaexNFT: zero amount");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "TaexNFT: not minter");
        _;
    }

    event TokenListedForSale(uint256 tokenId, uint256 price);
    event TokenUnListedForSale(uint256 tokenId);
    event TokenPriceAdjusted(uint256 tokenId, uint256 price);
    event TokenMinted(address indexed to, uint256 tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _primaryPrice,
        address _minter
    ) isNotZero(_primaryPrice) ERC721(_name, _symbol) Ownable(msg.sender) {
        internalBaseURI = _uri;
        primaryPrice = _primaryPrice;
        minter = _minter;
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

    /**
     * @dev mint function
     */
    function mint(
        address to
    ) external onlyMinter nonReentrant isNotZeroAddress(to) returns (uint256) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        tokenPrice[tokenId] = primaryPrice;
        _safeMint(to, tokenId);
        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Check if an address is a minter
     * @return true or false based on minter status.
     */
    function isMinter(
        address account
    ) public view isNotZeroAddress(minter) returns (bool) {
        return minter == account;
    }

    /**
     * @dev External function to change minter
     */
    function setMinter(
        address account
    ) external onlyOwner isNotZeroAddress(account) {
        minter = account;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return internalBaseURI;
    }
}
