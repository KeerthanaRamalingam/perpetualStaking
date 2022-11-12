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

    const ERC20Reward = await ethers.getContractFactory("MockERC20");
    const TokenInstanceERC20Reward = await ERC20Reward.deploy("1000000000000000000000000000")
    console.log("RewardToken ERC20", TokenInstanceERC20Reward.address);
    const rewardToken = TokenInstanceERC20Reward.address;

    const MockERC721 = await ethers.getContractFactory("MockERC721");
    const TokenInstanceMockERC721 = await MockERC721.deploy()
    console.log("ERC721 Address", TokenInstanceMockERC721.address);
    const ERC721TokenAddress = TokenInstanceMockERC721.address;

    const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
    const perpetualStaking = await upgrades.deployProxy(PerpetualStaking, { initializer: "initialize" });
    console.log("Perpetual Staking Proxy : ", perpetualStaking.address);

    // Example ERC20 Pool
    await perpetualStaking.deployNewPool(ERC20TokenAddress, 1668272647, 1668272647 + 2592000, 0, [rewardToken], [2]);
    // Example ERC721 Pool
    await perpetualStaking.deployNewPool(ERC721TokenAddress, 1668272647, 1668272647 + 2592000, 0, [rewardToken], [2]);

    await new Promise(res => setTimeout(res, 25000));

    const pools = await perpetualStaking.poolsDeployed();
    console.log("ERC20 pool address : ", pools[0]);
    console.log("ERC721 pool address : ", pools[1]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })