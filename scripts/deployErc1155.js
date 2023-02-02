const { ethers } = require("hardhat");
async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log("Accounts: ", accounts[0]);

    //Deposit token ERC1155 

    const ERC1155 = await ethers.getContractFactory("MockERC1155");
    const erc1155Instance = await ERC1155.deploy();
    //const erc1155Instance = await ERC1155.attach("0xCdc85Ad88A218EDcCF955138b458ABEfC91dc8a2");
    console.log("ERC1155 Address", erc1155Instance.address);

    // //Reward ERC20

    const ERC20Reward = await ethers.getContractFactory("MockERC20Reward");
    const TokenInstanceERC20Reward = await ERC20Reward.deploy("1000000000000000000000000000");
    // //const TokenInstanceERC20Reward = await ERC20Reward.attach("0x6b0c3b64c22fb2e6e00D68CE8284E5aBE1Fa0DF5");
    console.log("RewardToken ERC20", TokenInstanceERC20Reward.address);
    const rewardToken = TokenInstanceERC20Reward.address;

    // //Perpetual Staking

    const PerpetualStaking = await ethers.getContractFactory("PerpetualErc1155");
    const perpetualStaking = await upgrades.deployProxy(PerpetualStaking, {initializer: "initialize"});
    // const perpetualStaking = await PerpetualStaking.attach("0x04013CB8543B22C84Cddcdd25B8678b9b2f71021");
    
    console.log("Perpetual Staking Proxy : ", perpetualStaking.address);

    // //Treasury

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = Treasury.attach("0x4f62754DF2a75b9D133Bf40C3C74873a702Be3Cf");
    // //const treasury = await Treasury.deploy();
    console.log("Treasury address :", treasury.address);
    // // await treasury.initialize(accounts[0]);

    // //Pool ERC1155
    await perpetualStaking.deployNewPool(erc1155Instance.address, 1675339344, 1675340544 , 20, [rewardToken], [2]);
    await new Promise(res => setTimeout(res, 10000));
    const pools = await perpetualStaking.poolsDeployed();
    console.log("ERC1155 pool address", pools[0]);

    // // Transfer reward to the erc1155 pool contract
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockERC20 = await MockERC20.attach(rewardToken);

    await mockERC20.transfer(pools[0], ethers.utils.parseUnits("10000", 18));

    //Admin functions for ERC1155 pool

    const PoolERC1155 = await ethers.getContractFactory("PoolERC1155");
    const poolERC1155 = await PoolERC1155.attach(pools[0]);

    await poolERC1155.updateTreasury(treasury.address);
    await poolERC1155.updatePlatformFee(100);

    //Approve and Deposit
    const MockERC1155 = await ethers.getContractFactory("MockERC1155");
    const mockERC1155 = await MockERC1155.attach(erc1155Instance.address);
    
    await mockERC1155.setApprovalForAll(pools[0], true);
    await new Promise(res => setTimeout(res, 10000));
    console.log("approved");

    await poolERC1155.deposit(2, 1);
    console.log("deposited");

    await new Promise(res => setTimeout(res, 10000));
    console.log("done");
    const rewardAmount = await poolERC1155.getReward(rewardToken, accounts[0], 1);
    
    // await poolERC1155.deposit(1, 100000000000);
    // await new Promise(res => setTimeout(res, 10000));
    // await poolERC1155.deposit(1, 50000000000);
    // await new Promise(res => setTimeout(res, 10000));
    // await poolERC1155.deposit(1, 50000000000);
    // await new Promise(res => setTimeout(res, 10000));

    console.log("rewardAmount", rewardAmount);
    // await poolERC1155.claimTokenReward(rewardToken);
    // await new Promise(res => setTimeout(res, 10000));
    // await poolERC1155.withdraw(2,1);
    // console.log("withdrawn");


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })

    // ERC1155 Address 0xE6fE478809d9eba2954cFf134bb35e8dfCAd5982
    // RewardToken ERC20 0x29C0fEF3D32Da9D28c8f992da7eBD91C07Ba91e7
    // Perpetual Staking Proxy :  0xC1e94E34d70dE6F64d977dA9D7189b869b6daBd6
    // Treasury address : 0x4f62754DF2a75b9D133Bf40C3C74873a702Be3Cf
    // ERC1155 pool address 0xe7667D3068330d08E107F3A6777FFbc19d724F0B