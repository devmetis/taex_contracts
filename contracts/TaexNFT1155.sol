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
        require(_address != address(0), "TaexNFT1155: zero address");
        _;
    }

    modifier isNotZero(uint256 amount) {
        require(amount > 0, "TaexNFT1155: zero amount");
        _;
    }

    event TokenListedForSale(uint256 indexed tokenId, uint256 price);
    event TokenUnListedForSale(uint256 indexed tokenId);
    event TokenPriceAdjusted(uint256 indexed tokenId, uint256 price);
    event TokenMinted(address indexed to, uint256 tokenId);

    constructor(
        string memory _uri,
        uint256 _primaryPrice,
        uint256 _primaryArtistFee,
        uint256 _secondaryArtistFee,
        uint256 _secondaryTaexFee
    ) isNotZero(_primaryPrice) ERC1155(_uri) Ownable(msg.sender) {
        internalBaseURI = _uri;
        primaryPrice = _primaryPrice;
        primaryArtistFee = _primaryArtistFee;
        secondaryArtistFee = _secondaryArtistFee;
        secondaryTaexFee = _secondaryTaexFee;
    }

    function ownerOfToken(uint256 _tokenId) external view returns (address) {
        return _owners[_tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, 1, "");
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

    function _mintTaex(
        address to,
        uint256 _primaryArtistFee,
        uint256 _secondaryArtistFee,
        uint256 _secondaryTaexFee
    ) internal returns (uint256) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        tokenPrice[tokenId] = primaryPrice;
        tokenPrimaryArtistFee[tokenId] = _primaryArtistFee;
        tokenSecondaryArtistFee[tokenId] = _secondaryArtistFee;
        tokenSecondaryTaexFee[tokenId] = _secondaryTaexFee;
        _mint(to, tokenId, 1, "");
        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    function mint(
        address to
    ) external onlyOwner nonReentrant isNotZeroAddress(to) returns (uint256) {
        return
            _mintTaex(
                to,
                primaryArtistFee,
                secondaryArtistFee,
                secondaryTaexFee
            );
    }

    function mintWithSpecifiedFee(
        address to,
        uint256 _primaryArtistFee,
        uint256 _secondaryArtistFee,
        uint256 _secondaryTaexFee
    ) external onlyOwner nonReentrant isNotZeroAddress(to) returns (uint256) {
        return
            _mintTaex(
                to,
                _primaryArtistFee,
                _secondaryArtistFee,
                _secondaryTaexFee
            );
    }
}
