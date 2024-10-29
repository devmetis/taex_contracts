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

    // Additional checks for unauthorized minting
    await expect(taexNFT.connect(user2).mint(user2)).to.be.revertedWith("NotAuthorized");
    await expect(taexNFT1155.connect(user2).mint(user2)).to.be.revertedWith("NotAuthorized");

    // Additional checks for minting errors
    await expect(taexNFT.connect(owner).mint(0)).to.be.revertedWith("InvalidMintAmount");
    await expect(taexNFT1155.connect(owner).mint(0)).to.be.revertedWith("InvalidMintAmount");
  });

  it("should fail if execute primarySale or secondarySale with a non-whiteListed contract", async function () {
    // Test with non-whitelisted contract
    await expect(
      saleNFT.connect(buyer).primarySale(
        user2,
        1,
        { value: ethers.parseEther("0.9") } // Less than 1 ETH
      )
    ).to.be.revertedWithCustomError(saleNFT, "NotWhitelistedNFT");

    // Test with invalid token ID
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        9999,
        { value: ethers.parseEther("1.0") }
      )
    ).to.be.revertedWithCustomError(saleNFT, "InvalidTokenID");

    // Test with insufficient ETH sent
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("0.5") } // Less than required price
      )
    ).to.be.revertedWithCustomError(saleNFT, "InsufficientAmount");

    // Test with token not approved for sale
    await taexNFT.connect(owner).revokeApproval(saleNFT.target, 1);
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("1.0") }
      )
    ).to.be.revertedWithCustomError(saleNFT, "TokenNotApproved");

    // Test secondary sale with token not listed for sale
    await expect(
      saleNFT.connect(buyer).secondarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("1.0") }
      )
    ).to.be.revertedWithCustomError(saleNFT, "NotListedForSale");
  });

  it("should successfully execute the primary sale", async function () {
    // Check initial balances
    const initialArtistBalance = new BigNumber(
      await ethers.provider.getBalance(artistTreasury.address)
    );
    const initialTaexBalance = new BigNumber(
      await ethers.provider.getBalance(taexTreasury.address)
    );
    const buyerInitialBalance = new BigNumber(
      await ethers.provider.getBalance(buyer.address)
    );

    // Execute the primary sale transaction from the buyer
    const tx = await saleNFT
      .connect(buyer)
      .primarySale(taexNFT.target, 1, { value: ethers.parseEther("1.0") });
    const receipt = await tx.wait();

    // Calculate expected artist fee and taex treasury share
    const expectedArtistFee = new BigNumber(primaryPrice)
      .multipliedBy(primaryArtistFee)
      .div(100);

    const expectedTaexShare = new BigNumber(primaryPrice).minus(
      expectedArtistFee
    );

    // Check final balances
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

    // Verify NFT ownership transferred
    expect(await taexNFT.ownerOfToken(1)).to.equal(buyer.address);

    // Additional edge case tests
    // Test with minimum fee values (0%)
    const zeroFeeNFT = await TaexNFT.connect(owner).deploy(
      "Zero Fee NFT",
      "ZFNT",
      "ipfs://",
      primaryPrice,
      0, // primaryArtistFee
      0, // secondaryArtistFee
      0 // secondaryTaexFee
    );
    await zeroFeeNFT.connect(owner).mint(owner);
    await zeroFeeNFT.connect(owner).approve(saleNFT.target, 1);
    await saleNFT.connect(owner).addToWhitelist(zeroFeeNFT.target);
    const txZeroFee = await saleNFT
      .connect(buyer)
      .primarySale(zeroFeeNFT.target, 1, { value: ethers.parseEther("1.0") });
    await txZeroFee.wait();
    expect(await zeroFeeNFT.ownerOfToken(1)).to.equal(buyer.address);

    // Test with maximum fee values (100%)
    const maxFeeNFT = await TaexNFT.connect(owner).deploy(
      "Max Fee NFT",
      "MFNT",
      "ipfs://",
      primaryPrice,
      100, // primaryArtistFee
      100, // secondaryArtistFee
      100 // secondaryTaexFee
    );
    await maxFeeNFT.connect(owner).mint(owner);
    await maxFeeNFT.connect(owner).approve(saleNFT.target, 1);
    await saleNFT.connect(owner).addToWhitelist(maxFeeNFT.target);
    await expect(
      saleNFT.connect(buyer).primarySale(maxFeeNFT.target, 1, { value: ethers.parseEther("1.0") })
    ).to.be.revertedWith("InvalidFeeConfiguration");
  });

  it("should fail if the sent ETH is less than the price", async function () {
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("0.9") } // Less than 1 ETH
      )
    ).to.be.revertedWithCustomError(saleNFT, "InsufficientAmount");

    // Test with exactly the required amount
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("1.0") } // Exact amount
      )
    ).to.not.be.reverted;

    // Check behavior with different contract states
    await taexNFT.connect(owner).revokeApproval(saleNFT.target, 1);
    await expect(
      saleNFT.connect(buyer).primarySale(
        taexNFT.target,
        1,
        { value: ethers.parseEther("1.0") }
      )
    ).to.be.revertedWithCustomError(saleNFT, "TokenNotApproved");
  });

  it("should fail if the token is not listed for sale", async function () {
    // Unlist the token for sale
    await expect(
      saleNFT
        .connect(buyer)
        .secondarySale(taexNFT.target, 1, { value: ethers.parseEther("1.2") })
    ).to.be.revertedWithCustomError(saleNFT, "NotListedForSale");
  });

  it("should successfully execute the secondary sale", async function () {
    // list the token for sale
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

    // Execute the secondary sale with 1.2 ETH (to test refund logic)
    const tx = await saleNFT.connect(buyer).secondarySale(
      taexNFT.target,
      1,
      { value: ethers.parseEther("1.2") } // Send more than the price to check refund
    );
    const receipt = await tx.wait(); // Wait for transaction to complete

    // Calculate expected fees and amounts
    const artistFeeAmount = new BigNumber(primaryPrice)
      .multipliedBy(secondaryArtistFee)
      .div(100);
    const taexFeeAmount = new BigNumber(primaryPrice)
      .multipliedBy(secondaryTaexFee)
      .div(100);
    const sellerAmount = new BigNumber(primaryPrice)
      .minus(artistFeeAmount)
      .minus(taexFeeAmount);

    // Check final balances
    const finalArtistBalance = new BigNumber(
      await ethers.provider.getBalance(artistTreasury.address)
    );
    const finalTaexBalance = new BigNumber(
      await ethers.provider.getBalance(taexTreasury.address)
    );
    const finalSellerBalance = new BigNumber(
      await ethers.provider.getBalance(owner.address)
    );

    // Verify fees and payments
    expect(finalArtistBalance.minus(initialArtistBalance)).to.equal(
      artistFeeAmount
    );
    expect(finalTaexBalance.minus(initialTaexBalance)).to.equal(taexFeeAmount);
    expect(finalSellerBalance.minus(initialSellerBalance)).to.equal(
      sellerAmount
    );

    // Verify NFT ownership transferred to the buyer
    expect(await taexNFT.ownerOf(1)).to.equal(buyer.address);

    // Additional test for handling multiple sales
    await taexNFT.connect(buyer).listForSale(1, primaryPrice);
    await saleNFT.connect(user2).secondarySale(taexNFT.target, 1, {
      value: ethers.parseEther("1.0"),
    });
    expect(await taexNFT.ownerOf(1)).to.equal(user2.address);

    // Additional test for different token IDs
    await taexNFT.connect(owner).mint(owner);
    await taexNFT.connect(owner).approve(saleNFT.target, 2);
    await taexNFT.connect(owner).listForSale(2, primaryPrice);
    await saleNFT.connect(buyer).secondarySale(taexNFT.target, 2, {
      value: ethers.parseEther("1.0"),
    });
    expect(await taexNFT.ownerOf(2)).to.equal(buyer.address);
  });
});
