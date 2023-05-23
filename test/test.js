const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('TestERC721r', function() {
  let TestERC721r;
  let testERC721r;
  let addr1;
  let addrs;

  beforeEach(async function() {
    TestERC721r = await ethers.getContractFactory('TestERC721r');
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    testERC721r = await TestERC721r.deploy("TestToken", "TTN", 100);
    await testERC721r.deployed();
  });

  describe("Deployment", function() {
    it("Should set the right values in constructor", async function() {
      expect(await testERC721r.name()).to.equal("TestToken");
      expect(await testERC721r.symbol()).to.equal("TTN");
      expect(await testERC721r.maxSupply()).to.equal(100);
    });
  });

  describe("Minting", function() {
    it("Should mint a token to an address", async function() {
      await testERC721r.mintRandom(addr1.address, 1);
      const balance = await testERC721r.balanceOf(addr1.address);
      expect(balance).to.equal(1);
    });

    it("Should mint a token at a specific index", async function() {
      await testERC721r.mintAtIndex(addr1.address, 5);
      const balance = await testERC721r.balanceOf(addr1.address);
      expect(balance).to.equal(1);
      
      const owner = await testERC721r.ownerOf(5);
      expect(owner).to.equal(addr1.address);
    });
  });

  describe("Address extra data", function() {
    it("Should set and get extra address data", async function() {
      await testERC721r.setExtraAddressData(addr1.address, 123);
      const data = await testERC721r.getAddressExtraData(addr1.address);
      expect(data).to.equal(123);
    });
  });

  describe("numberMinted", function() {
    it("Should return correct number of minted tokens", async function() {
      const numToMint = 5;
      await testERC721r.mintRandom(addr1.address, numToMint);
      const numberMinted = await testERC721r.numberMinted(addr1.address);
      expect(numberMinted).to.equal(numToMint);
    });
  });

  describe("Contract Minting", function() {
    it("Should not allow contracts to mint tokens", async function() {
      let TestERC721rContractMinting = await ethers.getContractFactory('TestERC721rContractMinting');
      TestERC721rContractMinting = await TestERC721rContractMinting.deploy();
      await TestERC721rContractMinting.deployed()

      await expect(TestERC721rContractMinting.testMint(
        testERC721r.address
      )).to.be.revertedWith("ContractsCannotMint");
    });
  });

  describe("Mint Constraints", function() {
    it("Should not allow minting 0 tokens", async function() {
      await expect(testERC721r.connect(addr1).mintRandom(addr1.address, 0)).
        to.be.revertedWith("MustMintAtLeastOneToken");
    });

    it("Should not allow minting more than max supply", async function() {
      const maxSupply = await testERC721r.maxSupply();

      await expect(testERC721r.connect(addr1).mintRandom(addr1.address, maxSupply.add(1))).
        to.be.revertedWith("NotEnoughAvailableTokens");
    });
  });

  describe("Extra Address Data", function() {
    it("Should set, get and not interfere with number of minted tokens", async function() {
      const numToMint = 50;
      await testERC721r.connect(addr1).mintRandom(addr1.address, numToMint);

      const extraData = BigInt(2) ** BigInt(100)
      await testERC721r.connect(addr1).setExtraAddressData(addr1.address, extraData);

      const returnedData = await testERC721r.connect(addr1).getAddressExtraData(addr1.address);
      expect(returnedData).to.equal(extraData);

      const numMinted = await testERC721r.connect(addr1).numberMinted(addr1.address);
      expect(numMinted).to.equal(numToMint);
    });
  });

  describe("totalSupply", function() {
    it("Should return correct total supply after minting", async function() {
      const numToMint = 5;
      await testERC721r.mintRandom(addr1.address, numToMint);
      const totalSupply = await testERC721r.totalSupply();
      expect(totalSupply).to.equal(numToMint);
    });
  });
  
  describe("Minting Edge Cases", function() {
    it("Should correctly mint at index 0 and last index", async function() {
      const maxSupply = await testERC721r.maxSupply();
      await testERC721r.mintAtIndex(addr1.address, 0);
      expect(await testERC721r.ownerOf(0)).to.equal(addr1.address);

      await testERC721r.mintAtIndex(addr1.address, maxSupply - 1);
      expect(await testERC721r.ownerOf(maxSupply - 1)).to.equal(addr1.address);
    });
  });

  describe("remainingSupply", function() {
    it("Should update remainingSupply correctly after minting", async function() {
      const remaining = await testERC721r.remainingSupply();
      const numToMint = 5;
      await testERC721r.mintRandom(addr1.address, numToMint);
      expect(await testERC721r.remainingSupply()).to.equal(remaining - numToMint);
    });
  });

  describe("Random Minting", function() {
    it("Should mint tokens in a non-sequential manner", async function() {
      const maxSupply = (await testERC721r.maxSupply()).toNumber();
      let mintedTokenIds = [];

      await testERC721r.mintRandom(addr1.address, 20);

      for (let i = 0; i < maxSupply; i++) {
        try {
          await testERC721r.ownerOf(i);
          mintedTokenIds.push(i);
        } catch (e) { }
      }

      let isSequential = true;
      for (let i = 1; i < mintedTokenIds.length; i++) {
        if (mintedTokenIds[i - 1] + 1 !== mintedTokenIds[i]) {
          isSequential = false;
          break;
        }
      }

      expect(isSequential).to.equal(false);
    });
  });

  describe("Full Supply Minting", function() {
    it("Should mint all tokens", async function() {
      const maxSupply = await testERC721r.maxSupply();

      for (let i = 0; i < (maxSupply / 10); i++) {
        await testERC721r.mintRandom(addr1.address, 10);
      }

      const endBalance = await testERC721r.balanceOf(addr1.address);
      expect(endBalance).to.equal(maxSupply);

      for (let tokenId = 0; tokenId < maxSupply; tokenId++) {
        const owner = await testERC721r.ownerOf(tokenId);
        expect(owner).to.equal(addr1.address);
      }
    });
  });
});
