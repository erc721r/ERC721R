# ERC721R

A fully-compliant implementation of IERC721 that selects token ids pseudo-randomly. You can read about its inspiration in [this Medium article](https://medium.com/@dumbnamenumbers/erc721r-a-new-erc721-contract-for-random-minting-so-people-dont-snipe-all-the-rares-68dd06611e5).

# March 15, 2023 update: how to use this contract

This contract is for entertainment purposes only! People using Flashbots will be able to predict what they will get and decide not to go through with the mint if they don't like it. There might also be other exploits I am not aware of because the "instant reveal" mint style is impossible to securely randomize.

If the randomness mechanic is an important part of your app, you really should move to a commit-reveal scheme where the user pays in a different transaction than they find out what they got.

Someday I will write a library for this, but for now [this MouseDev thread is a good place to start](https://twitter.com/_MouseDev/status/1623044314983964682).

# Usage

```solidity
contract FashionHatPunks is ERC721r {
    // 10_000 is the number of tokens in the colletion
    constructor() ERC721r("Fashion Hat Punks", "HATPUNK", 10_000) {}
    
    function mint(uint quantity) {
        _mintRandom(msg.sender, quantity);
    }
}
```

There is also the function `_mintAtIndex(address to, uint index)` which allows you to mint non-randomly, but it will only behave as you expect if you:

1. Use it before minting randomly
2. Mint non-random tokens in decreasing order of id. E.g., if you want to mint id 200 to one person and id 100 to another person, you should mint id 200 first (because 200 > 100).

ERC721R pseudo-random numbers are generated like this:

```solidity
uint256 randomNum = uint256(
    keccak256(
        abi.encode(
            mintTargetAddress,
            tx.gasprice,
            block.number,
            block.timestamp,
            block.difficulty,
            blockhash(block.number - 1),
            address(this),
            updatedNumAvailableTokens
        )
    )
);
```

Miners can game this, but the assumption is that in most cases it will not be worth the cost on their part.

Finally, ERC721R exposes public `totalSupply()` and `maxSupply()` functions.

# Notes

- ERC721r assumes the first id is 0

# Implementation notes

ERC721R uses the [modern version of the Fisher–Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_modern_algorithm) which stores the list of available tokens and the list of minted tokens in one data structure to save gas.

# Limitations

- At this time ERC721R does not include `safeMint()` functionality. This is the result of the original author's position that the benefits of preventing users from minting to the wrong contract are outweighed by the cost of increasing surface area for reentrancy attacks.
- ERC721R disallows contracts from minting for security reasons. [Read more](https://medium.com/@dumbnamenumbers/erc721r-a-new-erc721-contract-for-random-minting-so-people-dont-snipe-all-the-rares-68dd06611e5).

# Credits

This contract was extracted from [Fashion Hat Punks](https://etherscan.io/address/0x1febcd663f11e2654f3f02f261bee477eeff73cd#code), where it was first used. The core logic and code was copied from [CryptoPhunksV2](https://etherscan.io/address/0xf07468eAd8cf26c752C676E43C814FEe9c8CF402#code). The repository structure was copied from [ERC721A](https://github.com/chiru-labs/ERC721A).

# License

Copyright (c) 2022 Tom Lehman. ERC721R is released under the [MIT License](https://opensource.org/licenses/MIT).
