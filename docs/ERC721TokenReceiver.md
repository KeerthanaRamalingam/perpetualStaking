# ERC721TokenReceiver







*ERC-721 interface for accepting safe transfers. See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.*

## Methods

### onERC721Received

```solidity
function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external nonpayable returns (bytes4)
```

The contract address is always the message sender. A wallet/broker/auction application MUST implement the wallet interface if it will accept safe transfers.

*Handle the receipt of a NFT. The ERC721 smart contract calls this function on the recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return of other than the magic value MUST result in the transaction being reverted. Returns `bytes4(keccak256(&quot;onERC721Received(address,address,uint256,bytes)&quot;))` unless throwing.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator | address | The address which called `safeTransferFrom` function. |
| _from | address | The address which previously owned the token. |
| _tokenId | uint256 | The NFT identifier which is being transferred. |
| _data | bytes | Additional data with no specified format. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | Returns `bytes4(keccak256(&quot;onERC721Received(address,address,uint256,bytes)&quot;))`. |




