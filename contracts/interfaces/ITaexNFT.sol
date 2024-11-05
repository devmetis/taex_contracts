// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITaexNFT {
    function tokenData(
        uint256 tokenId
    )
        external
        view
        returns (
            bool isListedForSale,
            uint8 primaryArtistFee,
            uint8 secondaryArtistFee,
            uint8 secondaryTaexFee,
            uint256 price
        );

    function ownerOfToken(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

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
}
