const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("TaexNFT", function () {
  let TaexNFT;
  let taexNFT;
  let owner;
  let user1, user2;

  beforeEach(async function () {
    TaexNFT = await ethers.getContractFactory("TaexNFT");

    [owner, user1, user2] = await ethers.getSigners();
    taexNFT = await TaexNFT.connect(owner).deploy(
      "Test NFT",
      "TNFT",
      "ipfs://",
      BigInt("100000000000000000"),
      85,
      10,
      10
    );
  });

  it("check if deploy initialized correctly", async function () {
    expect(await taexNFT.name()).to.equal("Test NFT");
    expect(await taexNFT.symbol()).to.equal("TNFT");
    expect(await taexNFT.internalBaseURI()).to.equal("ipfs://");
  });

  it("should mint only owner", async function () {
    await expect(taexNFT.connect(user1).mint(user1.address))
      .to.be.revertedWithCustomError(taexNFT, "OwnableUnauthorizedAccount")
      .withArgs(user1.address);
  });

  it("check if minting correctly", async function () {
    await taexNFT.connect(owner).mint(owner);
    expect(await taexNFT.ownerOfToken(1)).to.equal(owner.address);
  });

  it("check if minting with specified fee correctly", async function () {
    await expect(
      taexNFT.connect(owner).mintWithSpecifiedFee(owner, 110, 12, 12)
    ).to.be.revertedWithCustomError(taexNFT, "InvalidFeePercentage");
    await expect(
      taexNFT.connect(owner).mintWithSpecifiedFee(owner, 80, 60, 60)
    ).to.be.revertedWithCustomError(taexNFT, "InvalidFeePercentage");

    await taexNFT.connect(owner).mintWithSpecifiedFee(owner, 70, 12, 12);
    expect(await taexNFT.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should list for sale only owner of tokenId", async function () {
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).transferFrom(owner, user1, 1);
    await expect(
      taexNFT.connect(owner).listForSale(1, BigInt("200000000000000000"))
    ).to.be.revertedWithCustomError(taexNFT, "NotOwnerOfTokenId");
  });

  it("check if changed token price and status of listed after listing for sale", async function () {
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).transferFrom(owner, user1, 1);
    await taexNFT.connect(user1).listForSale(1, BigInt("200000000000000000"));
    const data = await taexNFT.tokenData(1);
    expect(data[0]).to.equal(true);
    expect(data[4]).to.equal(BigInt("200000000000000000"));
  });

  it("should unlist from sale only owner of tokenId", async function () {
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).transferFrom(owner, user1, 1);
    await expect(
      taexNFT.connect(owner).unlistFromSale(1)
    ).to.be.revertedWithCustomError(taexNFT, "NotOwnerOfTokenId");
  });

  it("check if changed status after unlisting from sale", async function () {
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).transferFrom(owner, user1, 1);
    await taexNFT.connect(user1).listForSale(1, BigInt("200000000000000000"));
    const data = await taexNFT.tokenData(1);
    expect(data[0]).to.equal(true);
    expect(data[4]).to.equal(BigInt("200000000000000000"));
    await taexNFT.connect(user1).unlistFromSale(1);
    const data1 = await taexNFT.tokenData(1);
    expect(data1[0]).to.equal(false);
  });

  it("should adjust price only owner of tokenId", async function () {
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).transferFrom(owner, user1, 1);
    await expect(
      taexNFT.connect(owner).adjustPrice(1, BigInt("200000000000000000"))
    ).to.be.revertedWithCustomError(taexNFT, "NotOwnerOfTokenId");
  });

  it("check if changed token price after adjust price", async function () {
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).transferFrom(owner, user1, 1);
    await taexNFT.connect(user1).adjustPrice(1, BigInt("200000000000000000"));
    const data = await taexNFT.tokenData(1);
    expect(data[4]).to.equal(BigInt("200000000000000000"));
  });
});
