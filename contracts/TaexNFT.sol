// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TaexNFT is ERC721, Ownable, ReentrancyGuard {
    uint256 private _lastTokenId;

    string public internalBaseURI;

    struct TokenData {
        bool isListedForSale;
        uint8 primaryArtistFee;
        uint8 secondaryArtistFee;
        uint8 secondaryTaexFee;
        uint256 price;
    }

    mapping(uint256 => TokenData) public tokenData;

    event TokenListedForSale(uint256 tokenId, uint256 price);
    event TokenUnlistedFromSale(uint256 tokenId);
    event TokenPriceAdjusted(uint256 tokenId, uint256 price);
    event TokenMinted(address indexed to, uint256 tokenId);
    event SetBaseURI(string);
    event SetDefaultData(uint256, uint8, uint8, uint8);

    error ZeroAddress();
    error ZeroAmount();
    error NotOwnerOfTokenId();
    error InvalidFeePercentage();

    modifier isNotZeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    modifier isNotZero(uint256 _amount) {
        if (_amount == 0) revert ZeroAmount();
        _;
    }

    modifier isValidFeePercentage(uint256 _percentage) {
        if (_percentage > 100) revert InvalidFeePercentage();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _primaryPrice,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    )
        isNotZero(_primaryPrice)
        isValidFeePercentage(_primaryArtistFee)
        isValidFeePercentage(_secondaryArtistFee + _secondaryTaexFee)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        internalBaseURI = _uri;
        tokenData[0].price = _primaryPrice; // Default primary price for future tokens
        tokenData[0].primaryArtistFee = _primaryArtistFee;
        tokenData[0].secondaryArtistFee = _secondaryArtistFee;
        tokenData[0].secondaryTaexFee = _secondaryTaexFee;
    }

    function ownerOfToken(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @dev Lists NFT for sale by the token's owner.
     */
    function listForSale(uint256 _tokenId, uint256 _price) external {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();

        tokenData[_tokenId].isListedForSale = true;
        tokenData[_tokenId].price = _price;

        emit TokenListedForSale(_tokenId, _price);
    }

    /**
     * @dev Unlists NFT from sale by the token's owner.
     */
    function unlistFromSale(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();

        tokenData[_tokenId].isListedForSale = false;

        emit TokenUnlistedFromSale(_tokenId);
    }

    /**
     * @dev Adjusts the price of an NFT by the token's owner.
     */
    function adjustPrice(uint256 _tokenId, uint256 _price) external {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();

        tokenData[_tokenId].price = _price;

        emit TokenPriceAdjusted(_tokenId, _price);
    }

    /**
     * @dev Internal function to mint NFTs with specified fees and data.
     */
    function _mintTaex(
        address to,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    ) internal returns (uint256) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;

        tokenData[tokenId] = TokenData({
            isListedForSale: false,
            price: tokenData[0].price, // Default primary price
            primaryArtistFee: _primaryArtistFee,
            secondaryArtistFee: _secondaryArtistFee,
            secondaryTaexFee: _secondaryTaexFee
        });

        _safeMint(to, tokenId);

        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Public function to mint NFTs by the contract owner.
     */
    function mint(
        address to
    ) external onlyOwner nonReentrant isNotZeroAddress(to) returns (uint256) {
        return
            _mintTaex(
                to,
                tokenData[0].primaryArtistFee,
                tokenData[0].secondaryArtistFee,
                tokenData[0].secondaryTaexFee
            );
    }

    /**
     * @dev Allows minting with custom fee values.
     */
    function mintWithSpecifiedFee(
        address to,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    )
        external
        isValidFeePercentage(_primaryArtistFee)
        isValidFeePercentage(_secondaryArtistFee + _secondaryTaexFee)
        onlyOwner
        nonReentrant
        isNotZeroAddress(to)
        returns (uint256)
    {
        return
            _mintTaex(
                to,
                _primaryArtistFee,
                _secondaryArtistFee,
                _secondaryTaexFee
            );
    }

    /**
     * @dev External function to set new Base URI only by admin
     */
    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        internalBaseURI = newBaseUri;
        emit SetBaseURI(newBaseUri);
    }

    /**
     * @dev External function to set primary price only by admin
     */
    function setDefaultData(
        uint256 _price,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    ) external isNotZero(_price) onlyOwner {
        tokenData[0].price = _price;
        tokenData[0].primaryArtistFee = _primaryArtistFee;
        tokenData[0].secondaryArtistFee = _secondaryArtistFee;
        tokenData[0].secondaryTaexFee = _secondaryTaexFee;
        emit SetDefaultData(
            _price,
            _primaryArtistFee,
            _secondaryArtistFee,
            _secondaryTaexFee
        );
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return internalBaseURI;
    }
}
