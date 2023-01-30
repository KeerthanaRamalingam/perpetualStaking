const { ethers } = require("hardhat");
const {
    time,
} = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log("Accounts : ", accounts[0]);

    const ERC20 = await ethers.getContractFactory("MockERC20");
    //const TokenInstancexEth = await ERC20.attach("0xd7f7124765ea92b8EEC704793ebFA1084D4EC116");
    const TokenInstancexEth = await ERC20.deploy("1000000000000000000000000000")
    console.log("ERC20 Address", TokenInstancexEth.address);
    const ERC20TokenAddress = TokenInstancexEth.address;

    const ERC20Reward = await ethers.getContractFactory("MockERC20Reward");
    //const TokenInstanceERC20Reward = await ERC20.attach("0x7CcD628065A15b8De4867cf63228D19cCFEa9B43");
    const TokenInstanceERC20Reward = await ERC20Reward.deploy("1000000000000000000000000000")
    console.log("RewardToken ERC20", TokenInstanceERC20Reward.address);
    const rewardToken = TokenInstanceERC20Reward.address;

    const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
    //const perpetualStaking = await PerpetualStaking.attach("0x655968315F7c595E50E7B3C59c8B8E5080674369")
    const perpetualStaking = await upgrades.deployProxy(PerpetualStaking, { initializer: "initialize" });
    console.log("Perpetual Staking Proxy : ", perpetualStaking.address);

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy();
    await treasury.initialize(accounts[0]);

    // Example ERC20 Pool
    await perpetualStaking.deployNewPool(ERC20TokenAddress, 1674560763, 1674562563, 20, [rewardToken], [1]);

    await new Promise(res => setTimeout(res, 10000));
    const pools = await perpetualStaking.poolsDeployed();
    console.log("ERC20 pool address : ", pools[0]);
    
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockERC20 = await MockERC20.attach(rewardToken);

    await mockERC20.transfer(pools[0], ethers.utils.parseUnits("10000", 18));

    const PoolERC20 = await ethers.getContractFactory("PoolERC20");
    const poolERC20 = await PoolERC20.attach(pools[0]);

    await poolERC20.updateTreasury(treasury.address);
    await poolERC20.updatePlatformFee(100);

    //approve

    await TokenInstancexEth.approve(poolERC20.address, "35000000000000");
    await new Promise(res => setTimeout(res, 10000));

    //deposit

    await poolERC20.deposit("10000000000000");
    await new Promise(res => setTimeout(res, 20000));
    console.log("done");
    const rewardAmount = await poolERC20.getReward(rewardToken, accounts[0], 1);
    console.log("rewardAmount", rewardAmount);


    
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })