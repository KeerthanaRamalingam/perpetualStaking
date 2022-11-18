
BSC testnet

ERC20 contract Address :  0x379312fB04aD1783D34B7C4FD676628aebfc7F98

RewardToken contract ERC20 :  0x3eee4E624f52915bF19a30189C317353173aEb87

ERC721 contract Address : 0x3Dd530B04F03553D2bfF6570Fa32DB67978a19Db

Perpetual Staking Proxy :  0x89fBfA4600b108A4ab45C5d1e538d9DC91B01d1E

ERC20 pool address :  0xcE90F49ed10EBdf2A1062d4a7D9d2B0a355c9789

ERC721 pool address :  0x9fc4F92fc331CB9A8CfD11C6297c65d9FC5ad751



Testing Flow for ERC20 Pool

1. Approve ERC20 token with having spender as ERC20 pool in ERC20 contract.

2. Call "Deposit" in  with amount within approved at step 1 in ERC20 pool contract.

3. To withdraw deposited amount call "withdraw" with the amount you want to take out in ERC20 pool contract.

4. To claim your reward call "claim" in ERC20 pool contract. All the reward accumulated from all the reward tokens will be transferred to your address.


