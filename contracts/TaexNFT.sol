// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TaexNFT Contract
 * @notice This contract implements an ERC721 NFT with additional features for listing, unlisting, and adjusting prices.
 */
contract TaexNFT is ERC721, Ownable2Step, ReentrancyGuard {
    uint256 private _lastTokenId;

    /// @notice Base URI for NFT metadata
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

    modifier validFees(uint8 _primaryArtistFee, uint8 _secondaryArtistFee, uint8 _secondaryTaexFee) {
        if (_primaryArtistFee > 50 || _secondaryArtistFee > 50 || _secondaryTaexFee > 50) {
            revert InvalidFeePercentage();
        }
        _;
    }

    /**
     * @notice Constructor to initialize the TaexNFT contract
     * @param _name The name of the NFT collection
     * @param _symbol The symbol of the NFT collection
     * @param _uri The base URI for the NFT metadata
     * @param _primaryPrice The default primary sale price for the NFTs
     * @param _primaryArtistFee The artist fee percentage for primary sales
     * @param _secondaryArtistFee The artist fee percentage for secondary sales
     * @param _secondaryTaexFee The Taex fee percentage for secondary sales
     */
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
        validFees(_primaryArtistFee, _secondaryArtistFee, _secondaryTaexFee)
        ERC721(_name, _symbol)
        Ownable2Step()
    {
        internalBaseURI = _uri;
        tokenData[0].price = _primaryPrice; // Default primary price for future tokens
        tokenData[0].primaryArtistFee = _primaryArtistFee;
        tokenData[0].secondaryArtistFee = _secondaryArtistFee;
        tokenData[0].secondaryTaexFee = _secondaryTaexFee;
    }

    /**
     * @notice Returns the owner of a given token ID
     * @param _tokenId The ID of the token to query
     * @return The address of the token owner
     */
    function ownerOfToken(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @notice Lists an NFT for sale
     * @param _tokenId The ID of the token to list for sale
     * @param _price The price at which the token will be listed
     */
    function listForSale(uint256 _tokenId, uint256 _price) external {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();

        tokenData[_tokenId].isListedForSale = true;
        tokenData[_tokenId].price = _price;

        emit TokenListedForSale(_tokenId, _price);
    }

    /**
     * @notice Unlists an NFT from sale
     * @param _tokenId The ID of the token to unlist from sale
     */
    function unlistFromSale(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();

        tokenData[_tokenId].isListedForSale = false;

        emit TokenUnlistedFromSale(_tokenId);
    }

    /**
     * @notice Adjusts the price of an NFT listed for sale
     * @param _tokenId The ID of the token for which the price will be adjusted
     * @param _price The new price for the token
     */
    function adjustPrice(uint256 _tokenId, uint256 _price) external {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();

        tokenData[_tokenId].price = _price;

        emit TokenPriceAdjusted(_tokenId, _price);
    }

    /**
     * @notice Internal function to mint an NFT with specified fees and data
     * @param to The address to receive the minted NFT
     * @param _primaryArtistFee The artist fee percentage for the primary sale
     * @param _secondaryArtistFee The artist fee percentage for the secondary sale
     * @param _secondaryTaexFee The Taex fee percentage for the secondary sale
     * @return The ID of the newly minted token
     */
    function _mintTaex(
        address to,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    ) internal validFees(_primaryArtistFee, _secondaryArtistFee, _secondaryTaexFee) returns (uint256) {
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
     * @notice Mints an NFT to the specified address
     * @param to The address to receive the minted NFT
     * @return The ID of the newly minted token
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
     * @notice Mints an NFT with custom fee values
     * @param to The address to receive the minted NFT
     * @param _primaryArtistFee The artist fee percentage for the primary sale
     * @param _secondaryArtistFee The artist fee percentage for the secondary sale
     * @param _secondaryTaexFee The Taex fee percentage for the secondary sale
     * @return The ID of the newly minted token
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
        validFees(_primaryArtistFee, _secondaryArtistFee, _secondaryTaexFee)
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
     * @notice Sets a new base URI for the NFT metadata
     * @param newBaseUri The new base URI to set
     */
    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        internalBaseURI = newBaseUri;
        emit SetBaseURI(newBaseUri);
    }

    /**
     * @notice Sets the default data for future tokens
     * @param _price The default price for future tokens
     * @param _primaryArtistFee The artist fee percentage for the primary sale
     * @param _secondaryArtistFee The artist fee percentage for the secondary sale
     * @param _secondaryTaexFee The Taex fee percentage for the secondary sale
     */
    function setDefaultData(
        uint256 _price,
        uint8 _primaryArtistFee,
        uint8 _secondaryArtistFee,
        uint8 _secondaryTaexFee
    ) external isNotZero(_price) validFees(_primaryArtistFee, _secondaryArtistFee, _secondaryTaexFee) onlyOwner {
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
     * @notice Returns the base URI for the NFT metadata
     * @return The base URI as a string
     */
    function _baseURI() internal view override returns (string memory) {
        return internalBaseURI;
    }
}
