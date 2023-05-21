// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC721} from "solady/src/tokens/ERC721.sol";
import {LibPRNG} from "solady/src/utils/LibPRNG.sol";
import {LibString} from "solady/src/utils/LibString.sol";

abstract contract ERC721r is ERC721 {
    using LibPRNG for LibPRNG.PRNG;
    using LibString for uint256;
    
    error ContractsCannotMint();
    error MustMintAtLeastOneToken();
    error NotEnoughAvailableTokens();
    
    string private _name;
    string private _symbol;
    
    mapping(uint256 => uint256) private _availableTokens;
    uint256 private _numAvailableTokens;
    
    uint256 public immutable maxSupply;
    
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) {
        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _numAvailableTokens = maxSupply_;
    }
    
    function totalSupply() public view virtual returns (uint256) {
        return maxSupply - _numAvailableTokens;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function numberMinted(address minter) public view virtual returns (uint32) {
        return uint32(ERC721._getAux(minter) >> 192);
    }

    function _mintRandom(address to, uint256 _numToMint) internal virtual {
        if (msg.sender != tx.origin) revert ContractsCannotMint();
        if (_numToMint == 0) revert MustMintAtLeastOneToken();
        if (_numAvailableTokens < _numToMint) revert NotEnoughAvailableTokens();
        
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty
        ))));
        
        uint256 updatedNumAvailableTokens = _numAvailableTokens;
        
        for (uint256 i; i < _numToMint; ) {
            uint256 randomIndex = prng.uniform(updatedNumAvailableTokens);

            uint256 tokenId = getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
            
            _mint(to, tokenId);
            
            --updatedNumAvailableTokens;
            
            unchecked {++i;}
        }
        
        _incrementAmountMinted(to, uint32(_numToMint));
        _numAvailableTokens = updatedNumAvailableTokens;
    }
    
    // Must be called in descending order of index
    function _mintAtIndex(address to, uint256 index) internal virtual {
        if (msg.sender != tx.origin) revert ContractsCannotMint();
        if (_numAvailableTokens == 0) revert NotEnoughAvailableTokens();
        
        uint256 tokenId = getAvailableTokenAtIndex(index, _numAvailableTokens);
        
        --_numAvailableTokens;
        _incrementAmountMinted(to, 1);
        
        _mint(to, tokenId);
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle. Code taken from CryptoPhunksV2
    function getAvailableTokenAtIndex(uint256 indexToUse, uint256 updatedNumAvailableTokens)
        private
        returns (uint256 result)
    {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 lastIndex = updatedNumAvailableTokens - 1;
        uint256 lastValInArray = _availableTokens[lastIndex];
        
        result = valAtIndex == 0 ? indexToUse : valAtIndex;
        
        if (indexToUse != lastIndex) {
            _availableTokens[indexToUse] = lastValInArray == 0 ? lastIndex : lastValInArray;
        }
        
        if (lastValInArray != 0) {
            delete _availableTokens[lastIndex];
        }
    }
    
    function _setExtraAddressData(address minter, uint192 extraData) internal virtual {
        uint32 numMinted = numberMinted(minter);
        
        ERC721._setAux(
            minter,
            uint224((uint256(numMinted) << 192)) | uint224(extraData)
        );
    }
    
    function _getAddressExtraData(address minter) internal view virtual returns (uint192) {
        return uint192(_getAux(minter));
    }
    
    function _incrementAmountMinted(address minter, uint32 newMints) private {
        uint32 numMinted = numberMinted(minter);
        uint32 newMintNumMinted = numMinted + uint32(newMints);
        uint224 auxData = ERC721._getAux(minter);
        
        ERC721._setAux(
            minter,
            uint224(uint256(newMintNumMinted) << 192) | uint224(uint192(auxData))
        );
    }
}