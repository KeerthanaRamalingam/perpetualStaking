const { ethers } = require("hardhat");
const {
    time,
} = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log("Accounts : ", accounts[0]);

    const ERC20TokenAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; //Change based on chain
    const ERC721TokenAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"; // Change based on chain

    const rewardToken = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // Change based on chain

    const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
    const perpetualStaking = await upgrades.deployProxy(PerpetualStaking, { initializer: "initialize" });
    console.log("Perpetual Staking Proxy : ", perpetualStaking.address);

    // Example ERC20 Pool
    await perpetualStaking.deployNewPool(ERC20TokenAddress, await time.latest(), await time.latest() + 240, 0, [rewardToken], [2]);
    // Example ERC721 Pool
    await perpetualStaking.deployNewPool(ERC721TokenAddress, await time.latest(), await time.latest() + 240, 0, [rewardToken], [2]);
    
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