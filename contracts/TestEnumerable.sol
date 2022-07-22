// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721R.sol';
import "./ERC721REnumerable.sol";

contract TestEnerumable is ERC721r, ERC721rEnumerable {     

    constructor(string memory name_, string memory symbol_, uint maxSupply_) 
        ERC721r(name_, symbol_, maxSupply_) {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256[] memory tokenIdxs, uint _numToMint)    
        internal
        virtual
        override(ERC721r, ERC721rEnumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, tokenIdxs, _numToMint);
    }

    function totalSupply()
        public 
        view        
        override(ERC721r, ERC721rEnumerable)
        returns (uint256)
    {
        return super.totalSupply();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721r, ERC721rEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }    

    function mint(uint quantity) public {        
        super._mintRandom(msg.sender, quantity);
    }

}