# ERC721REnumerable

The standard OZ ERC721Enumerable doesn't work with batch mints (i.e. ```_mintRandom``` with ```_numToMint``` > 1 ). This is due to the way ```_addTokenToOwnerEnumeration``` is implemented. 

```_addTokenToOwnerEnumeration``` is called inside ```_beforeTokenTransfer``` whenever tokens are minted or transferred. Here is how that function is normally implemented:

```
function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721r.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
}
```

When a batch mint event occurs this function fails to properly update the ```_ownedTokens``` mapping becuase the owner's balance is not stateful, meaning it is not updated on each mint iteration. Therefore, each iteration overwrites the previous ```tokenId``` until the final iteration is published to the blockchain.

To fix this we need to pass state down through the call stack so that we can understand how to to properly update the ```_ownedTokens``` mapping during a batch mint event.

The implementation I propose is as follows:

```
function _addTokenToOwnerEnumeration(address to, uint256 tokenId, uint256[] memory tokenIds, uint _numToMint ) private {        
    uint256 length = ERC721r.balanceOf(to);
    
    if(tokenIds.length == _numToMint){
        for( uint i=0; i<tokenIds.length; ++i){
            _ownedTokens[to][length+i] = tokenIds[i];        
        }             
    }

    _ownedTokensIndex[tokenId] = length;
}
```    

You see we are adding two variables to the ```_addTokenToOwnerEnumeration``` function: tokenIds(uint256[] memory), _numToMint (uint). Both of these are passed down from the original ERC721r ```_mintRandom``` and ```_mintAtIndex``` functions. 

The ```tokenIds``` array contains all the randomly selected tokenIds for a signle mint event.

Each iteration within ```_mintRandom``` then calls ```_mintIdWithoutBalanceUpdate``` which calls ```_beforeTokenTransfer``` which finally calls ```_addTokenToOwnerEnumeration``` at which stage checks to see if the tokenIds array length is equal to the _numToMint and, if so, updates the _ownedTokens appropriately.

I recognize that this may not be the most gas-efficient way to patch this issue. But it tests well on my end and I wanted to get ball rolling in this direction in case anyone has better ideas for implementing ERC721Enumerable for batch mints.

# Update 

Per middlemarch.eth suggestion, we removed the need for the if-statement operation inside ```_addTokenToOwnerEnumeration()``` by implementing two loops within the ```mintRandom()``` function. 

The first loop collects all the random tokenIds: 

```
for (uint256 i; i < _numToMint; ++i) { // Do this ++ unchecked?
    uint256 tokenId = getRandomAvailableTokenId(to, updatedNumAvailableTokens);
    tokenIds[i] = tokenId;                        
    --updatedNumAvailableTokens;
}
```

We then call ```_beforeTokenTransfer()``` pass it the ```tokenIds``` array. 

Once the ```_beforeTokenTransfer()``` completes we execute another loop to mint all the random tokenIds: 

```
for (uint256 i; i < _numToMint; ++i) { // using _numToMint to avoid tokenIds.length() call
    _mintIdWithoutBalanceUpdate(to, tokenIds[i]);
} 
```

We understand the 2 loop operations (3 including the loop in ```_beforeTokenTransfer```) may become costly given a large ```_numToMint``` value, but should be fine for small mint values.