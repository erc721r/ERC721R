# ERC721R

An ERC721 base contract that mints tokens in a pseudo-random order. Because the token is revealed in the same transaction as the mint itself, this contract creates a fun but not fully secure experience.

# This contract is for entertainment purposes only!

People using Flashbots will be able to predict what they will get and decide not to go through with the mint if they don't like it. There might also be other exploits I am not aware of because the "instant reveal" mint style is impossible to securely randomize.

If the randomness mechanic is an important part of your app, you really should move to a commit-reveal scheme where the user pays in a different transaction than they find out what they got. Unfortunately this costs more gas and is less fun, so weigh this against the benefit of increased security.

If you want to learn more about this, but for now [this MouseDev thread is a good place to start](https://twitter.com/_MouseDev/status/1623044314983964682).

# Usage

```solidity
contract FashionHatPunks is ERC721r {
    // 10_000 is the collection's maxSupply
    constructor() ERC721r("Fashion Hat Punks", "HATPUNK", 10_000) {}
    
    function mint(uint quantity) {
        // ERC721r exposes a public numberMinted(address) that you can use
        // to, e.g., enforce limits instead of using a separate mapping(address => uint)
        // which is more expensive
        require(numberMinted(msg.sender) <= 10, "Limit 10 per address");
        
        _mintRandom(msg.sender, quantity);
    }
}
```

Erc721r exposes public `maxSupply()`, `totalSupply()` and `remainingSupply()` functions automatically.

It inherits from [Solady's ERC721](https://github.com/Vectorized/solady/blob/main/src/tokens/ERC721.sol) so you also get `_getExtraData()`, `_setExtraData()`, `_getAux()`, and `_setAux()`. However you should be aware that `aux` is internally by ERC721R, so you should not use them in your own contract. Instead, use `_setExtraAddressData()` and `_getExtraAddressData()`.

There is also the function `_mintAtIndex(address to, uint index)` which allows you to mint non-randomly, but it will only behave as you expect if you:

1. Use it before minting randomly
2. Mint non-random tokens in decreasing order of id. E.g., if you want to mint id 200 to one person and id 100 to another person, you should mint id 200 first (because 200 > 100).

# Notes

* ERC721r assumes the first id is 0
* Max balance is type(uint32).max
* Contracts cannot mint

# Implementation notes

ERC721R uses the [modern version of the Fisher–Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_modern_algorithm) which stores the list of available tokens and the list of minted tokens in one data structure to save gas.

# Credits

This contract was extracted from [Fashion Hat Punks](https://etherscan.io/address/0x1febcd663f11e2654f3f02f261bee477eeff73cd#code), where it was first used. The core logic and code was copied from [CryptoPhunksV2](https://etherscan.io/address/0xf07468eAd8cf26c752C676E43C814FEe9c8CF402#code). The repository structure was copied from [ERC721A](https://github.com/chiru-labs/ERC721A). You can read about its inspiration in [this Medium article](https://medium.com/@dumbnamenumbers/erc721r-a-new-erc721-contract-for-random-minting-so-people-dont-snipe-all-the-rares-68dd06611e5).

# License

Copyright (c) 2022 Tom Lehman. ERC721R is released under the [MIT License](https://opensource.org/licenses/MIT).