// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {ITaexNFT} from "./interfaces/ITaexNFT.sol";

/**
 * @title TaexNFT1155
 * @dev Implementation of an ERC1155 NFT contract for managing token sales and fees.
 */
contract TaexNFT1155 is ERC1155, Ownable, ReentrancyGuard, ITaexNFT {
    using Strings for uint256;
    using Arrays for uint256[];

    uint256 private _lastTokenId;
    mapping(uint256 => address) private _owners;
    string public internalBaseURI;

    struct TokenData {
        bool isListedForSale; // 1 byte
        uint8 primaryArtistFee; // 1 byte (0-100%)
        uint8 secondaryArtistFee; // 1 byte (0-100%)
        uint8 secondaryTaexFee; // 1 byte (0-100%)
        uint256 price; // 32 bytes
    }

    mapping(uint256 => TokenData) public tokenData;

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
        string memory _uri,
        uint256 _primaryPrice,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    )
        isNotZero(_primaryPrice)
        isValidFeePercentage(_primaryArtistFee)
        isValidFeePercentage(_secondaryArtistFee + _secondaryTaexFee)
        ERC1155(_uri)
        Ownable(msg.sender)
    {
        internalBaseURI = _uri;
        tokenData[0].price = _primaryPrice; // Default primary price
        tokenData[0].primaryArtistFee = _primaryArtistFee;
        tokenData[0].secondaryArtistFee = _secondaryArtistFee;
        tokenData[0].secondaryTaexFee = _secondaryTaexFee;
    }

    /**
     * @dev Returns the owner of a given token ID.
     * @param _tokenId The ID of the token to query
     * @return The address of the token owner
     */
    function ownerOfToken(uint256 _tokenId) external view returns (address) {
        return _owners[_tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, 1, "");
    }
    /**
     * @dev Lists an NFT for sale.
     * @param _tokenId The ID of the token to list
     * @param _price The price at which the token will be listed for sale
     */
    function listForSale(uint256 _tokenId, uint256 _price) external {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotOwnerOfTokenId();
        tokenData[_tokenId].isListedForSale = true;
        tokenData[_tokenId].price = _price;

        emit TokenListedForSale(_tokenId, _price);
    }

    /**
     * @dev Unlists an NFT from sale.
     * @param _tokenId The ID of the token to unlist
     */
    function unlistFromSale(uint256 _tokenId) external {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotOwnerOfTokenId();
        tokenData[_tokenId].isListedForSale = false;

        emit TokenUnlistedFromSale(_tokenId);
    }

    /**
     * @dev Adjusts the price of an NFT.
     * @param _tokenId The ID of the token to adjust
     * @param _price The new price for the token
     */
    function adjustPrice(uint256 _tokenId, uint256 _price) external {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotOwnerOfTokenId();
        require(
            _price != tokenData[_tokenId].price,
            "New price must be different"
        );

        tokenData[_tokenId].price = _price;

        emit TokenPriceAdjusted(_tokenId, _price);
    }

    /**
     * @dev Retrieves the token URI.
     * @param _tokenId The ID of the token to query
     * @return The token URI as a string
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory baseURI = internalBaseURI;
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, _tokenId.toString())
                : "";
    }

    /**
     * @dev Updates ownership during token transfer.
     */
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
    /**
     * @dev Internal function to mint a new NFT.
     * @param to The address to mint the token to
     * @param _primaryArtistFee Primary artist fee percentage
     * @param _secondaryArtistFee Secondary artist fee percentage
     * @param _secondaryTaexFee Secondary Taex fee percentage
     * @return The ID of the minted token
     */
    function _mintTaex(
        address to,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    ) internal returns (uint256) {
        _lastTokenId++;
        uint256 tokenId = _lastTokenId;

        tokenData[tokenId] = TokenData({
            isListedForSale: false,
            price: tokenData[0].price,
            primaryArtistFee: _primaryArtistFee,
            secondaryArtistFee: _secondaryArtistFee,
            secondaryTaexFee: _secondaryTaexFee
        });

        _mint(to, tokenId, 1, "");

        emit TokenMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Mints a new NFT.
     * @param to The address to mint the token to
     * @return The ID of the minted token
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
     * @dev Mints an NFT with custom fee values.
     * @param to The address to mint the token to
     * @param _primaryArtistFee Primary artist fee percentage
     * @param _secondaryArtistFee Secondary artist fee percentage
     * @param _secondaryTaexFee Secondary Taex fee percentage
     * @return The ID of the minted token
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
     * @dev External function to set a new Base URI only by admin
     * @param newBaseUri New base URI for token metadata
     */
    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        internalBaseURI = newBaseUri;
        emit SetBaseURI(newBaseUri);
    }

    /**
     * @dev External function to set default data only by admin
     * @param _price New primary price
     * @param _primaryArtistFee New primary artist fee
     * @param _secondaryArtistFee New secondary artist fee
     * @param _secondaryTaexFee New secondary Taex fee
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
}
