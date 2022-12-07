const { ethers } = require("hardhat");
const {
    time,
} = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log("Accounts : ", accounts[0]);

    // const ERC20TokenAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; //Change based on chain
    // const ERC721TokenAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"; // Change based on chain

    // const rewardToken = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // Change based on chain

    const ERC20 = await ethers.getContractFactory("MockERC20");
    const TokenInstancexEth = await ERC20.deploy("1000000000000000000000000000")
    console.log("ERC20 Address", TokenInstancexEth.address);
    const ERC20TokenAddress = TokenInstancexEth.address;

    const ERC20Reward = await ethers.getContractFactory("MockERC20Reward");
    const TokenInstanceERC20Reward = await ERC20Reward.deploy("1000000000000000000000000000")
    console.log("RewardToken ERC20", TokenInstanceERC20Reward.address);
    const rewardToken = TokenInstanceERC20Reward.address;

    // const MockERC721 = await ethers.getContractFactory("MockERC721");
    // const TokenInstanceMockERC721 = await MockERC721.deploy()
    // console.log("ERC721 Address", TokenInstanceMockERC721.address);
    const ERC721TokenAddress = "0x3Dd530B04F03553D2bfF6570Fa32DB67978a19Db";//TokenInstanceMockERC721.address;

    const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
    const perpetualStaking = await upgrades.deployProxy(PerpetualStaking, { initializer: "initialize" });
    console.log("Perpetual Staking Proxy : ", perpetualStaking.address);

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy();
    await treasury.initialize(accounts[0]);

    // Example ERC20 Pool
    await perpetualStaking.deployNewPool(ERC20TokenAddress, 1670415685, 1670415685 + 2592000, 0, [rewardToken], [1]);
    // Example ERC721 Pool
    // await perpetualStaking.deployNewPool(ERC721TokenAddress, 1669386922, 1669386922 + 2592000, 0, [rewardToken], [2]);
    await new Promise(res => setTimeout(res, 10000));
    const pools = await perpetualStaking.poolsDeployed();
    console.log("ERC20 pool address : ", pools[0]);
    // console.log("ERC721 pool address : ", pools[1]);

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockERC20 = await MockERC20.attach(rewardToken);

    await mockERC20.transfer(pools[0], ethers.utils.parseUnits("10000", 18));

    const PoolERC20 = await ethers.getContractFactory("PoolERC20");
    const poolERC20 = await PoolERC20.attach(pools[0]);

    await poolERC20.updateTreasury(treasury.address);
    await poolERC20.updatePlatformFee(100);

    await new Promise(res => setTimeout(res, 25000));


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })