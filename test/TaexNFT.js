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
      100000
    );
  });

  it("check if deploy initialized correctly", async function () {
    expect(await taexNFT.name()).to.equal("Test NFT");
    expect(await taexNFT.symbol()).to.equal("TNFT");
    expect(await taexNFT.internalBaseURI()).to.equal("ipfs://");
    expect(await taexNFT.primaryPrice()).to.equal(100000);
  });
});
