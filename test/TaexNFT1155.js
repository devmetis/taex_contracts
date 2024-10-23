const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("TaexNFT1155", function () {
  let TaexNFT1155;
  let taexNFT1155;
  let owner;
  let user1, user2;

  beforeEach(async function () {
    TaexNFT1155 = await ethers.getContractFactory("TaexNFT1155");

    [owner, user1, user2] = await ethers.getSigners();
    taexNFT1155 = await TaexNFT1155.connect(owner).deploy(
      "ipfs://",
      BigInt("100000000000000000"),
      85,
      10,
      10
    );
  });

  it("check if deploy initialized correctly", async function () {
    expect(await taexNFT1155.internalBaseURI()).to.equal("ipfs://");
  });

  it("should mint only owner", async function () {
    await expect(taexNFT1155.connect(user1).mint(user1.address))
      .to.be.revertedWithCustomError(taexNFT1155, "OwnableUnauthorizedAccount")
      .withArgs(user1.address);
  });

  it("check if minting correctly", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    expect(await taexNFT1155.ownerOfToken(1)).to.equal(owner.address);
  });

  it("check if minting with specified fee correctly", async function () {
    await expect(
      taexNFT1155.connect(owner).mintWithSpecifiedFee(owner, 110, 12, 12)
    ).to.be.revertedWithCustomError(taexNFT1155, "InvalidFeePercentage");
    await expect(
      taexNFT1155.connect(owner).mintWithSpecifiedFee(owner, 80, 60, 60)
    ).to.be.revertedWithCustomError(taexNFT1155, "InvalidFeePercentage");

    await taexNFT1155.connect(owner).mintWithSpecifiedFee(owner, 70, 12, 12);
    expect(await taexNFT1155.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should list for sale only owner of tokenId", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    await taexNFT1155.connect(owner).transferFrom(owner, user1, 1);
    await expect(
      taexNFT1155.connect(owner).listForSale(1, BigInt("200000000000000000"))
    ).to.be.revertedWithCustomError(taexNFT1155, "NotOwnerOfTokenId");
  });

  it("check if changed token price and status of listed after listing for sale", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    await taexNFT1155.connect(owner).transferFrom(owner, user1, 1);
    await taexNFT1155.connect(user1).listForSale(1, BigInt("200000000000000000"));
    const data = await taexNFT1155.tokenData(1);
    expect(data[0]).to.equal(true);
    expect(data[4]).to.equal(BigInt("200000000000000000"));
  });

  it("should unlist from sale only owner of tokenId", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    await taexNFT1155.connect(owner).transferFrom(owner, user1, 1);
    await expect(
      taexNFT1155.connect(owner).unlistFromSale(1)
    ).to.be.revertedWithCustomError(taexNFT1155, "NotOwnerOfTokenId");
  });

  it("check if changed status after unlisting from sale", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    await taexNFT1155.connect(owner).transferFrom(owner, user1, 1);
    await taexNFT1155.connect(user1).listForSale(1, BigInt("200000000000000000"));
    const data = await taexNFT1155.tokenData(1);
    expect(data[0]).to.equal(true);
    expect(data[4]).to.equal(BigInt("200000000000000000"));
    await taexNFT1155.connect(user1).unlistFromSale(1);
    const data1 = await taexNFT1155.tokenData(1);
    expect(data1[0]).to.equal(false);
  });

  it("should adjust price only owner of tokenId", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    await taexNFT1155.connect(owner).transferFrom(owner, user1, 1);
    await expect(
      taexNFT1155.connect(owner).adjustPrice(1, BigInt("200000000000000000"))
    ).to.be.revertedWithCustomError(taexNFT1155, "NotOwnerOfTokenId");
  });

  it("check if changed token price after adjust price", async function () {
    await taexNFT1155.connect(owner).mint(owner);
    await taexNFT1155.connect(owner).transferFrom(owner, user1, 1);
    await taexNFT1155.connect(user1).adjustPrice(1, BigInt("200000000000000000"));
    const data = await taexNFT1155.tokenData(1);
    expect(data[4]).to.equal(BigInt("200000000000000000"));
  });
});
