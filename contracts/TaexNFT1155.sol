// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

contract TaexNFT1155 is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Arrays for uint256[];

    uint256 private _lastTokenId;
    mapping(uint256 => address) private _owners;

    string public internalBaseURI;
    address public minter;
    uint256 public primaryPrice;
    mapping(uint256 => bool) public isListedForSale;
    mapping(uint256 => uint256) public tokenPrice;

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "TaexNFT1155: zero address");
        _;
    }

    modifier isNotZero(uint256 amount) {
        require(amount > 0, "TaexNFT1155: zero amount");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "TaexNFT1155: not minter");
        _;
    }

    event TokenListedForSale(uint256 indexed tokenId, uint256 price);
    event TokenUnListedForSale(uint256 indexed tokenId);
    event TokenPriceAdjusted(uint256 indexed tokenId, uint256 price);
    event TokenMinted(address indexed to, uint256 tokenId);

    constructor(
        string memory _uri,
        uint256 _primaryPrice,
        address _minter
    ) isNotZero(_primaryPrice) ERC1155(_uri) Ownable(msg.sender) {
        internalBaseURI = _uri;
        primaryPrice = _primaryPrice;
        minter = _minter;
    }

    function ownerOfToken(uint256 _tokenId) external view returns (address) {
        return _owners[_tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, 1, "");
    }

    /**
     * @dev Check if an address is a minter.
     */
    function isMinter(
        address account
    ) public view isNotZeroAddress(minter) returns (bool) {
        return minter == account;
    }

    /**
     * @dev Mint function that allows only the minter to mint new tokens.
     * Each token has a unique `tokenId` and the `amount` must always be 1 to ensure NFTs.
     */
    function mint(
        address to
    ) external onlyMinter nonReentrant isNotZeroAddress(to) returns (uint256) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        _mint(to, tokenId, 1, "");
        tokenPrice[tokenId] = primaryPrice;
        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev External function to list NFT for sale by the token's owner.
     */
    function listForSale(uint256 _tokenId, uint256 _price) external {
        require(
            balanceOf(msg.sender, _tokenId) > 0,
            "TaexNFT1155: caller is not owner of tokenId"
        );
        isListedForSale[_tokenId] = true;
        tokenPrice[_tokenId] = _price;
        emit TokenListedForSale(_tokenId, _price);
    }

    /**
     * @dev External function to unlist the token from sale.
     */
    function unlistFromSale(uint256 _tokenId) external {
        require(
            balanceOf(msg.sender, _tokenId) > 0,
            "TaexNFT1155: caller is not owner of tokenId"
        );
        isListedForSale[_tokenId] = false;
        emit TokenUnListedForSale(_tokenId);
    }

    /**
     * @dev External function to adjust the price of an NFT.
     */
    function adjustPrice(uint256 _tokenId, uint256 _price) external {
        require(
            balanceOf(msg.sender, _tokenId) > 0,
            "TaexNFT1155: caller is not owner of tokenId"
        );
        tokenPrice[_tokenId] = _price;
        emit TokenPriceAdjusted(_tokenId, _price);
    }

    /**
     * @dev External function to set a new base URI (can only be set by the owner).
     */
    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        internalBaseURI = newBaseUri;
    }

    /**
     * @dev External function to change the primary price of tokens (can only be set by the owner).
     */
    function setPrimaryPrice(
        uint256 _price
    ) external isNotZero(_price) onlyOwner {
        primaryPrice = _price;
    }

    /**
     * @dev External function to change the minter address (only the owner can set a new minter).
     */
    function setMinter(
        address account
    ) external onlyOwner isNotZeroAddress(account) {
        minter = account;
    }

    /**
     * @dev tokenURI to implement the same functionality as TaexNFT ERC721.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(
            balanceOf(msg.sender, _tokenId) > 0,
            "TaexNFT1155: caller is not owner of tokenId"
        );

        string memory baseURI = internalBaseURI;
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, _tokenId.toString())
                : "";
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override {
        super._update(from, to, ids, values);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids.unsafeMemoryAccess(i);
            _owners[id] = to;
        }
    }
}
