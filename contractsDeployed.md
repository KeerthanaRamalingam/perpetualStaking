
BSC testnet

ERC20 Address : 0x5E00F74FcbCeea21c34C1C8af4E3e14F422668Ab

RewardToken ERC20 : 0x8177A87F4FA8F7ff32d16C2475f2E80cEF77485b

Perpetual Staking Proxy :  0x801eF241dbB2fb40cCe72B1d78a204A95e23c566

ERC20 pool address :  0xEf38d24327eb37F850740b70b5C69d60b4A5B4C2



Testing Flow for ERC20 Pool

1. Approve ERC20 token with having spender as ERC20 pool in ERC20 contract.

2. Call "Deposit" in  with amount within approved at step 1 in ERC20 pool contract.

3. To withdraw deposited amount call "withdraw" with the amount you want to take out in ERC20 pool contract.

4. To claim your reward call "claim" in ERC20 pool contract. All the reward accumulated from all the reward tokens will be transferred to your address.


