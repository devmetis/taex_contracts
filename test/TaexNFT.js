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
      ethers.parseEther("0.1"), // 0.1 ETH
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

  it("should only allow owner to mint", async function () {
    await expect(taexNFT.connect(user1).mint(user1.address))
      .to.be.revertedWithCustomError(taexNFT, "OwnableUnauthorizedAccount")
      .withArgs(user1.address);
  });

  it("should mint correctly", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    expect(await taexNFT.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should enforce valid fee percentages when minting with specified fees", async function () {
    await expect(
      taexNFT.connect(owner).mintWithSpecifiedFee(owner.address, 110, 12, 12)
    ).to.be.revertedWithCustomError(taexNFT, "InvalidFeePercentage");
    await expect(
      taexNFT.connect(owner).mintWithSpecifiedFee(owner.address, 80, 60, 60)
    ).to.be.revertedWithCustomError(taexNFT, "InvalidFeePercentage");

    await taexNFT
      .connect(owner)
      .mintWithSpecifiedFee(owner.address, 70, 12, 12);
    expect(await taexNFT.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should only allow the owner of tokenId to list for sale", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    await taexNFT.connect(owner).transferFrom(owner.address, user1.address, 1);
    await expect(
      taexNFT.connect(owner).listForSale(1, ethers.parseEther("0.2"))
    ).to.be.revertedWithCustomError(taexNFT, "NotOwnerOfTokenId");
  });

  it("should update token status and price after listing for sale", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    await taexNFT.connect(owner).transferFrom(owner.address, user1.address, 1);
    await taexNFT.connect(user1).listForSale(1, ethers.parseEther("0.2"));

    const data = await taexNFT.tokenData(1);
    expect(data[0]).to.equal(true); // Listed for sale
    expect(data[4]).to.equal(ethers.parseEther("0.2")); // Sale price
  });

  it("should only allow the owner of tokenId to unlist from sale", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    await taexNFT.connect(owner).transferFrom(owner.address, user1.address, 1);
    await expect(
      taexNFT.connect(owner).unlistFromSale(1)
    ).to.be.revertedWithCustomError(taexNFT, "NotOwnerOfTokenId");
  });

  it("should update status after unlisting from sale", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    await taexNFT.connect(owner).transferFrom(owner.address, user1.address, 1);
    await taexNFT.connect(user1).listForSale(1, ethers.parseEther("0.2"));

    expect((await taexNFT.tokenData(1))[0]).to.equal(true);
    await taexNFT.connect(user1).unlistFromSale(1);
    expect((await taexNFT.tokenData(1))[0]).to.equal(false);
  });

  it("should only allow the owner of tokenId to adjust price", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    await taexNFT.connect(owner).transferFrom(owner.address, user1.address, 1);
    await expect(
      taexNFT.connect(owner).adjustPrice(1, ethers.parseEther("0.2"))
    ).to.be.revertedWithCustomError(taexNFT, "NotOwnerOfTokenId");
  });

  it("should update token price after adjustment", async function () {
    await taexNFT.connect(owner).mint(owner.address);
    await taexNFT.connect(owner).transferFrom(owner.address, user1.address, 1);
    await taexNFT.connect(user1).adjustPrice(1, ethers.parseEther("0.2"));

    const data = await taexNFT.tokenData(1);
    expect(data[4]).to.equal(ethers.parseEther("0.2")); // Check new price
  });
});
