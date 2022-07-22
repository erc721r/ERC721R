const { expect } = require("chai");

describe("ERC721REnumerable Test", function () {

  it("Deploy, Mint All and Log New Tokens ", async function () {

    const numTokens = 10;
    const [owner] = await ethers.getSigners();

    const TestEnerumable = await ethers.getContractFactory("TestEnerumable");

    const contract = await TestEnerumable.deploy('TestEnerumable', 'Test', numTokens);

    await contract.mint(numTokens);

    for(i=0; i<numTokens; i++){
        tokenId = await contract.tokenOfOwnerByIndex(owner.address, i)
        console.log(`TokenId: ${tokenId}`)
    }

    expect(await contract.balanceOf(owner.address)).to.equal(numTokens);
  });

});