// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestERC721r} from "./TestERC721r.sol";

contract TestERC721rContractMinting {
    function testMint(address erc721R) external {
        TestERC721r(erc721R).mintRandom(address(this), 2);
    }
}
