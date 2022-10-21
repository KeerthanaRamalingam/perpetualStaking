# Sample Hardhat Project

Perpetual Staking

Deposit 
-> ERC20,ERC721,ERC1155

Reward 
-> per unit of deposit asset 

-> per block

-> Only ERC20

-> Multiple reward tokens

-> Can be same as deposit token

Questions:

Deposits and Rewards are stored seperately -> in different contracts?

Step 1: Deploy Perpetual Staking contract 

Step 2: Call "deployNewPool" with token address and other details
        New pool will be deployed based on tokenAddress, 
        If ERC20 tokenaddress is passed, PoolERC20 will be deployed
        If ERC721 token address is passed PoolERC721 will be deployed

Step 3: Transfer reward to Pool contract, update Maturity date, platformFee and reward per deposit for reward tokens

Step 4: Call "Deposit" in Pool contract 

Step 5: Call "Wwithdraw" after cliff period to withdraw the deposit funds

Step 6: Call "Claim" to claim reward after cliff


