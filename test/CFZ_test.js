const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CryptoFrensCollection contract", function () {

  let owner;
  let addr1, addr2, addr3;
  let cfz;
  let CryptoFrenzCollection;
  let minter1, minter2, minter3;

  beforeEach(async function () {

    CryptoFrenzCollection = await ethers.getContractFactory("CryptoFrenzCollection");

    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    cfz = await CryptoFrenzCollection.deploy('CryptoFrenzCollection', 'CFZ', 'http://gateway.pinata.cloud/ipfs/QmZyQnieh8Pd1w5k4KQodKFHxApvRVpPtNGHdRR6bgkNLo/');
    await cfz.deployed();

    minter1 = {
      address: addr1,
      signature: "0x0d843947ae2ff5f08a00faebade470c0e76817141be9bf78b8ea181315fc3db013d2d9f2f7d8abb9978399a553548af5058dfd8352bde3941c1bb74e139eb37a1b"
    };

    minter2 = {
      address: addr2,
      signature: "0x2e63cbb75bd8d1f8e4d8c519f611ec2f4e9711f520f7594957b7ef32cb76f10d6cf251db275146d2119045ff951af132972fc19043f11b473a2522cf2bd949431b"
    };

    minter3 = addr3;
  });

  describe("Opensale activated by contract owner", function () {
    it("Should return true bool on saleIsActive getter", async function () {

        await cfz.connect(owner).flipSaleState();
        let saleState = await cfz.saleIsActive();

        expect(saleState).to.equal(true);
    });
  });

  describe("Opensale failed", function () {
    it("Should return revert (Caller is not the owner) after calling saleIsActive() from addr1", async function () {

        await expect(cfz.connect(addr1).flipSaleState())
          .to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Mint from whitelist", function() {
    it("Should return owner of expected token Id", async function () {

      let expectedTokenId = 0;

      await cfz.connect(owner).flipSaleState();
      await cfz.connect(owner).setWhitelistKey('0xEA51b8077980f5F3c2c382de599161a3C66D04b9');
      await cfz.connect(addr1).mintFromWhitelist('1', minter1.signature);

      expect(await cfz.ownerOf(expectedTokenId)).to.equal(addr1.address);
    });
  });

  describe("Mint from whitelist failed", function() {
    it("Should revert while minting from not whitelisted address", async function() {

      await cfz.connect(owner).flipSaleState();
      await cfz.connect(owner).setWhitelistKey('0xEA51b8077980f5F3c2c382de599161a3C66D04b9');

      await expect(cfz.connect(addr3).mintFromWhitelist('1', minter2.signature))
        .to.be.reverted;
    });
  });

  describe("Withdraw contract earnings from owner address", function () {
    it("Should transact fund from contract to owner address", async function() {

      await cfz.connect(owner).flipSaleState();
      await cfz.connect(addr1).mintCard(5, {value: ethers.utils.parseEther("0.15") });
      await cfz.connect(addr2).mintCard(5, {value: ethers.utils.parseEther("0.15") });

      await expect(await cfz.connect(owner).withdraw()).
        to.changeEtherBalance(owner, ethers.utils.parseEther("0.3"));
    });
  });
});
