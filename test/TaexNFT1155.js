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
      ethers.parseEther("0.1"), // 0.1 ETH
      85,
      10,
      10
    );
  });

  it("should initialize correctly", async function () {
    expect(await taexNFT1155.internalBaseURI()).to.equal("ipfs://");
  });

  it("should allow only the owner to mint", async function () {
    await expect(taexNFT1155.connect(user1).mint(user1.address))
      .to.be.revertedWithCustomError(taexNFT1155, "OwnableUnauthorizedAccount")
      .withArgs(user1.address);
  });

  it("should mint correctly and set owner", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    expect(await taexNFT1155.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should enforce valid fee percentages when minting with specified fees", async function () {
    await expect(
      taexNFT1155
        .connect(owner)
        .mintWithSpecifiedFee(owner.address, 110, 12, 12)
    ).to.be.revertedWithCustomError(taexNFT1155, "InvalidFeePercentage");
    await expect(
      taexNFT1155.connect(owner).mintWithSpecifiedFee(owner.address, 80, 60, 60)
    ).to.be.revertedWithCustomError(taexNFT1155, "InvalidFeePercentage");

    await taexNFT1155
      .connect(owner)
      .mintWithSpecifiedFee(owner.address, 70, 12, 12);
    expect(await taexNFT1155.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should allow only the owner of tokenId to list for sale", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    await taexNFT1155
      .connect(owner)
      .transferFrom(owner.address, user1.address, 1);
    await expect(
      taexNFT1155.connect(owner).listForSale(1, ethers.parseEther("0.2"))
    ).to.be.revertedWithCustomError(taexNFT1155, "NotOwnerOfTokenId");
  });

  it("should change token price and status after listing for sale", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    await taexNFT1155
      .connect(owner)
      .transferFrom(owner.address, user1.address, 1);
    await taexNFT1155.connect(user1).listForSale(1, ethers.parseEther("0.2"));

    const data = await taexNFT1155.tokenData(1);
    expect(data[0]).to.equal(true); // Listed for sale
    expect(data[4]).to.equal(ethers.parseEther("0.2")); // Sale price
  });

  it("should allow only the owner of tokenId to unlist from sale", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    await taexNFT1155
      .connect(owner)
      .transferFrom(owner.address, user1.address, 1);
    await expect(
      taexNFT1155.connect(owner).unlistFromSale(1)
    ).to.be.revertedWithCustomError(taexNFT1155, "NotOwnerOfTokenId");
  });

  it("should change status after unlisting from sale", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    await taexNFT1155
      .connect(owner)
      .transferFrom(owner.address, user1.address, 1);
    await taexNFT1155.connect(user1).listForSale(1, ethers.parseEther("0.2"));

    const data = await taexNFT1155.tokenData(1);
    expect(data[0]).to.equal(true);

    await taexNFT1155.connect(user1).unlistFromSale(1);
    const updatedData = await taexNFT1155.tokenData(1);
    expect(updatedData[0]).to.equal(false); // Check status is now unlisted
  });

  it("should allow only the owner of tokenId to adjust price", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    await taexNFT1155
      .connect(owner)
      .transferFrom(owner.address, user1.address, 1);
    await expect(
      taexNFT1155.connect(owner).adjustPrice(1, ethers.parseEther("0.2"))
    ).to.be.revertedWithCustomError(taexNFT1155, "NotOwnerOfTokenId");
  });

  it("should change token price after adjustment", async function () {
    await taexNFT1155.connect(owner).mint(owner.address);
    await taexNFT1155
      .connect(owner)
      .transferFrom(owner.address, user1.address, 1);
    await taexNFT1155.connect(user1).adjustPrice(1, ethers.parseEther("0.2"));

    const data = await taexNFT1155.tokenData(1);
    expect(data[4]).to.equal(ethers.parseEther("0.2")); // Check new price
  });
});
