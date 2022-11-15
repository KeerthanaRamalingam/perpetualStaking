# PoolERC20









## Methods

### claim

```solidity
function claim() external nonpayable
```






### claimWithToken

```solidity
function claimWithToken(address tokenAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |

### claimWithTokenAndAmount

```solidity
function claimWithTokenAndAmount(address tokenAddress, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |
| amount | uint256 | undefined |

### claimed

```solidity
function claimed(address tokenAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### depositToken

```solidity
function depositToken() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getReward

```solidity
function getReward(address tokenAddress, address user, uint256 depositID) external view returns (uint256 lastReward)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |
| user | address | undefined |
| depositID | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| lastReward | uint256 | undefined |

### getRewardPerUnitOfDeposit

```solidity
function getRewardPerUnitOfDeposit(address tokenAddress) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### lastTimeRewardApplicable

```solidity
function lastTimeRewardApplicable() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### maturityDate

```solidity
function maturityDate() external view returns (uint256)
```






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

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### startDate

```solidity
function startDate() external view returns (uint256)
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

### treasuryContract

```solidity
function treasuryContract() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### updateMaturityDate

```solidity
function updateMaturityDate(uint256 newMaturityDate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newMaturityDate | uint256 | undefined |

### updatePlatformFee

```solidity
function updatePlatformFee(uint256 newPlatformFee) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newPlatformFee | uint256 | undefined |

### updateTreasuryContract

```solidity
function updateTreasuryContract(address _treasuryContract) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _treasuryContract | address | undefined |

### userDeposit

```solidity
function userDeposit(address userAddress, uint256 poolCount) external view returns (struct PoolERC20.Deposit depositdetails)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userAddress | address | undefined |
| poolCount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| depositdetails | PoolERC20.Deposit | undefined |

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



