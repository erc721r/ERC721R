// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721r} from "./ERC721R.sol";

contract TestERC721r is ERC721r {
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC721r(name_, symbol_, maxSupply_) {}

    function tokenURI(uint256) public view virtual override returns (string memory ret) {}

    function mintRandom(address to, uint256 _numToMint) public {
        _mintRandom(to, _numToMint);
    }

    function mintAtIndex(address to, uint256 index) public {
        _mintAtIndex(to, index);
    }

    function getAddressExtraData(address minter) public view returns (uint192) {
        return _getAddressExtraData(minter);
    }

    function setExtraAddressData(address minter, uint192 extraData) public {
        _setExtraAddressData(minter, extraData);
    }
}
