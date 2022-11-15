# PerpetualStaking









## Methods

### IID_IERC1155

```solidity
function IID_IERC1155() external view returns (bytes4)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### IID_IERC721

```solidity
function IID_IERC721() external view returns (bytes4)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### deployNewPool

```solidity
function deployNewPool(address depositToken_, uint256 startDate_, uint256 maturityDate_, uint256 cliff_, address[] rewardTokens_, uint256[] rewardUnits_) external nonpayable returns (address)
```

Owner function to deploy new pools - ERC20,ERC721,ERC1155



#### Parameters

| Name | Type | Description |
|---|---|---|
| depositToken_ | address | Token for which pool is to be created |
| startDate_ | uint256 | Start time of the pool |
| maturityDate_ | uint256 | Maturity time of the pool |
| cliff_ | uint256 | Cliff of the pool |
| rewardTokens_ | address[] | Reward token addresses of the pool. Expected to be ERC20 tokens |
| rewardUnits_ | uint256[] | Reward Units to be given per deposit |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | Deployed pool address |

### initialize

```solidity
function initialize() external nonpayable
```






### isERC1155

```solidity
function isERC1155(address nftAddress) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isERC721

```solidity
function isERC721(address nftAddress) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### poolsDeployed

```solidity
function poolsDeployed() external view returns (address[])
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### NewPoolCreated

```solidity
event NewPoolCreated(address depositToken, uint256 startDate, uint256 maturityDate, uint256 cliff, address poolAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| depositToken  | address | undefined |
| startDate  | uint256 | undefined |
| maturityDate  | uint256 | undefined |
| cliff  | uint256 | undefined |
| poolAddress  | address | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



