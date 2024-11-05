const { expect } = require("chai");
const { FixedNumber } = require("ethers");
const BigNumber = require("bignumber.js");

describe("SaleNFT", function () {
  let SaleNFT;
  let saleNFT;
  let TaexNFT;
  let taexNFT;
  let TaexNFT1155;
  let taexNFT1155;
  let owner;
  let artistTreasury, taexTreasury;
  let buyer, user2;
  let primaryPrice = ethers.parseEther("1.0");
  let primaryArtistFee = 85,
    secondaryArtistFee = 10,
    secondaryTaexFee = 10;

  beforeEach(async function () {
    SaleNFT = await ethers.getContractFactory("SaleNFT");

    [owner, buyer, user2, artistTreasury, taexTreasury] =
      await ethers.getSigners();
    saleNFT = await SaleNFT.connect(owner).deploy(artistTreasury, taexTreasury);

    TaexNFT = await ethers.getContractFactory("TaexNFT");
    taexNFT = await TaexNFT.connect(owner).deploy(
      "Test NFT",
      "TNFT",
      "ipfs://",
      primaryPrice,
      primaryArtistFee,
      secondaryArtistFee,
      secondaryTaexFee
    );

    TaexNFT1155 = await ethers.getContractFactory("TaexNFT1155");
    taexNFT1155 = await TaexNFT1155.connect(owner).deploy(
      "ipfs://",
      primaryPrice,
      primaryArtistFee,
      secondaryArtistFee,
      secondaryTaexFee
    );

    await saleNFT.connect(owner).addToWhitelist(taexNFT.target);

    await saleNFT.connect(owner).addToWhitelist(taexNFT1155.target);

    await taexNFT.connect(owner).mint(owner);

    await taexNFT.connect(owner).approve(saleNFT.target, 1);

    await taexNFT1155.connect(owner).mint(owner);
  });

  it("check if deploy initialized correctly", async function () {
    expect(await saleNFT.artistTreasury()).to.equal(artistTreasury.address);
    expect(await saleNFT.taexTreasury()).to.equal(taexTreasury.address);
  });

  it("check if minting correctly", async function () {
    expect(await taexNFT.ownerOfToken(1)).to.equal(owner.address);
    expect(await taexNFT1155.ownerOfToken(1)).to.equal(owner.address);
  });

  it("should fail if execute primarySale or secondarySale with a non-whitelisted contract", async function () {
    await expect(
      saleNFT.connect(buyer).primarySale(
        user2,
        1,
        { value: ethers.parseEther("0.9") } // Less than 1 ETH
      )
    ).to.be.revertedWithCustomError(saleNFT, "NotWhitelistedNFT");
  });

  it("should successfully execute the primary sale", async function () {
    const initialArtistBalance = new BigNumber(
      await ethers.provider.getBalance(artistTreasury.address)
    );
    const initialTaexBalance = new BigNumber(
      await ethers.provider.getBalance(taexTreasury.address)
    );

    const buyerInitialBalance = new BigNumber(
      await ethers.provider.getBalance(buyer.address)
    );
    const tx = await saleNFT
      .connect(buyer)
      .primarySale(taexNFT.target, 1, { value: ethers.parseEther("1.2") });
    await tx.wait();

    const expectedArtistFee = new BigNumber(primaryPrice)
      .multipliedBy(primaryArtistFee)
      .div(100);
    const expectedTaexShare = new BigNumber(primaryPrice).minus(
      expectedArtistFee
    );

    const finalArtistBalance = new BigNumber(
      await ethers.provider.getBalance(artistTreasury.address)
    );
    const finalTaexBalance = new BigNumber(
      await ethers.provider.getBalance(taexTreasury.address)
    );

    const buyerFinalBalance = new BigNumber(
      await ethers.provider.getBalance(buyer.address)
    );
    expect(finalArtistBalance.minus(initialArtistBalance)).to.equal(
      expectedArtistFee
    );
    expect(finalTaexBalance.minus(initialTaexBalance)).to.equal(
      expectedTaexShare
    );
    expect(await taexNFT.ownerOfToken(1)).to.equal(buyer.address);
  });

  it("should fail if the sent ETH is less than the price", async function () {
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("0.9") } // Less than 1 ETH
      )
    ).to.be.revertedWithCustomError(saleNFT, "InsufficientAmount");
  });

  it("should fail if the token is not listed for sale", async function () {
    await expect(
      saleNFT
        .connect(buyer)
        .secondarySale(taexNFT.target, 1, { value: ethers.parseEther("1.2") })
    ).to.be.revertedWithCustomError(saleNFT, "NotListedForSale");
  });

  it("should successfully execute the secondary sale", async function () {
    await taexNFT.connect(owner).listForSale(1, primaryPrice);

    const initialArtistBalance = new BigNumber(
      await ethers.provider.getBalance(artistTreasury.address)
    );
    const initialTaexBalance = new BigNumber(
      await ethers.provider.getBalance(taexTreasury.address)
    );
    const initialSellerBalance = new BigNumber(
      await ethers.provider.getBalance(owner.address)
    );

    const tx = await saleNFT.connect(buyer).secondarySale(
      taexNFT.target,
      1,
      { value: ethers.parseEther("1.2") } // Send more than the price to check refund
    );
    await tx.wait();

    const artistFeeAmount = new BigNumber(primaryPrice)
      .multipliedBy(secondaryArtistFee)
      .div(100);
    const taexFeeAmount = new BigNumber(primaryPrice)
      .multipliedBy(secondaryTaexFee)
      .div(100);
    const sellerAmount = new BigNumber(primaryPrice)
      .minus(artistFeeAmount)
      .minus(taexFeeAmount);

    const finalArtistBalance = new BigNumber(
      await ethers.provider.getBalance(artistTreasury.address)
    );
    const finalTaexBalance = new BigNumber(
      await ethers.provider.getBalance(taexTreasury.address)
    );
    const finalSellerBalance = new BigNumber(
      await ethers.provider.getBalance(owner.address)
    );

    expect(finalArtistBalance.minus(initialArtistBalance)).to.equal(
      artistFeeAmount
    );
    expect(finalTaexBalance.minus(initialTaexBalance)).to.equal(taexFeeAmount);
    expect(finalSellerBalance.minus(initialSellerBalance)).to.equal(
      sellerAmount
    );
    expect(await taexNFT.ownerOfToken(1)).to.equal(buyer.address);
  });

  it("should correctly process exact ETH sent for primary sale", async function () {
    await saleNFT
      .connect(buyer)
      .primarySale(taexNFT.target, 1, { value: primaryPrice });
    expect(await taexNFT.ownerOfToken(1)).to.equal(buyer.address);
  });

  it("should handle case with no fees correctly", async function () {
    // Set fees to zero for the test
    await taexNFT.connect(owner).setDefaultData(primaryPrice, 0, 0, 0); // Assuming there's a function to set fees

    await saleNFT
      .connect(buyer)
      .primarySale(taexNFT.target, 1, { value: primaryPrice });
    expect(await taexNFT.ownerOfToken(1)).to.equal(buyer.address);
  });

  it("should refund excess ETH correctly on secondary sale", async function () {
    await taexNFT.connect(owner).listForSale(1, primaryPrice);

    const initialSellerBalance = new BigNumber(
      await ethers.provider.getBalance(owner.address)
    );

    const tx = await saleNFT.connect(buyer).secondarySale(
      taexNFT.target,
      1,
      { value: ethers.parseEther("10.0") } // Send more than the price
    );
    await tx.wait();

    const expectedSellerAmount = new BigNumber(primaryPrice).minus(
      new BigNumber(primaryPrice)
        .multipliedBy(secondaryArtistFee)
        .div(100)
        .plus(
          new BigNumber(primaryPrice).multipliedBy(secondaryTaexFee).div(100)
        )
    );

    const finalSellerBalance = new BigNumber(
      await ethers.provider.getBalance(owner.address)
    );
    expect(finalSellerBalance.minus(initialSellerBalance)).to.equal(
      expectedSellerAmount
    );
  });

  it("should maintain ownership after a failed sale", async function () {
    await expect(
      saleNFT
        .connect(buyer)
        .primarySale(taexNFT.target, 1, { value: ethers.parseEther("0.9") }) // Should fail
    ).to.be.revertedWithCustomError(saleNFT, "InsufficientAmount");
    expect(await taexNFT.ownerOfToken(1)).to.equal(owner.address); // Ensure ownership hasn't changed
  });

  it("should allow ownership transfer after listing for sale", async function () {
    await taexNFT.connect(owner).listForSale(1, primaryPrice);
    await taexNFT.connect(owner).transferFrom(owner.address, user2.address, 1);

    expect(await taexNFT.ownerOfToken(1)).to.equal(user2.address);
  });
});
