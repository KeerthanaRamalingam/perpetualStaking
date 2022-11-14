
BSC testnet

ERC20 contract Address :  0x379312fB04aD1783D34B7C4FD676628aebfc7F98

RewardToken contract ERC20 :  0x3eee4E624f52915bF19a30189C317353173aEb87

ERC721 contract Address : 0x3Dd530B04F03553D2bfF6570Fa32DB67978a19Db

Perpetual Staking Proxy :  0x9694a2177E602b5934C40d477CAb5030AC9E53a6

ERC20 pool address :  0xec80cC5dcC3a86C815c8ef33ab787361FFa81779

ERC721 pool address :  0xB0C93744EFa95af874EE9178fAb26EE772a388bA



Testing Flow for ERC20 Pool

1. Approve ERC20 token with having spender as ERC20 pool in ERC20 contract.

2. Call "Deposit" in  with amount within approved at step 1 in ERC20 pool contract.

3. To withdraw deposited amount call "withdraw" with the amount you want to take out in ERC20 pool contract.

4. To claim your reward call "claim" in ERC20 pool contract. All the reward accumulated from all the reward tokens will be transferred to your address.


