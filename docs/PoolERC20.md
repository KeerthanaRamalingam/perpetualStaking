# PoolERC20









## Methods

### accruedReward

```solidity
function accruedReward(address userAddress) external view returns (uint256 rewardAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| rewardAmount | uint256 | undefined |

### claimAllReward

```solidity
function claimAllReward() external nonpayable
```

Claim the total rewards from all reward tokens




### claimTokenReward

```solidity
function claimTokenReward(address rewardTokenAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rewardTokenAddress | address | undefined |

### cliff

```solidity
function cliff() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### deposit

```solidity
function deposit(uint256 amount) external nonpayable
```

Users deposit &quot;Deposit token&quot; to the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Amount of token to deposit |

### depositDetailsByID

```solidity
function depositDetailsByID(address userAddress, uint256 depositIndex) external view returns (struct PoolERC20.Deposit depositdetails)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |
| depositIndex | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| depositdetails | PoolERC20.Deposit | undefined |

### depositToken

```solidity
function depositToken() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### endDate

```solidity
function endDate() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getRewardPerUnitOfDeposit

```solidity
function getRewardPerUnitOfDeposit(address rewardTokenAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rewardTokenAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### platformFee

```solidity
function platformFee() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### rewardToken

```solidity
function rewardToken(uint256 rewardTokenIndex) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rewardTokenIndex | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rewardTokenCount

```solidity
function rewardTokenCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### startDate

```solidity
function startDate() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalClaimed

```solidity
function totalClaimed(address rewardTokenAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rewardTokenAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalDeposit

```solidity
function totalDeposit() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### treasury

```solidity
function treasury() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### updateEndDate

```solidity
function updateEndDate(uint256 _endDate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _endDate | uint256 | undefined |

### updatePlatformFee

```solidity
function updatePlatformFee(uint256 newPlatformFee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newPlatformFee | uint256 | undefined |

### updateTreasury

```solidity
function updateTreasury(address newContractAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newContractAddress | address | undefined |

### userClaimed

```solidity
function userClaimed(address userAddress, address rewardTokenAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |
| rewardTokenAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### userDeposit

```solidity
function userDeposit(address userAddress) external view returns (uint256 depositAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| depositAmount | uint256 | undefined |

### userDepositCount

```solidity
function userDepositCount(address userAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### userTotalWithdrawl

```solidity
function userTotalWithdrawl(address userAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |



## Events

### Claim

```solidity
event Claim(address tokenAddress, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress  | address | undefined |
| amount  | uint256 | undefined |

### MaturityDate

```solidity
event MaturityDate(uint256 updatedMaturityDate)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| updatedMaturityDate  | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### PlatformFee

```solidity
event PlatformFee(uint256 platformFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFee  | uint256 | undefined |

### RewardForTokens

```solidity
event RewardForTokens(uint256[] reward, address[] tokenAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| reward  | uint256[] | undefined |
| tokenAddress  | address[] | undefined |

### Withdraw

```solidity
event Withdraw(address tokenAddress, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress  | address | undefined |
| amount  | uint256 | undefined |



