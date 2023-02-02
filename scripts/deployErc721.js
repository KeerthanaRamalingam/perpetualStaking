const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log("Accounts: ", accounts[0]);

    //Erc721 contract

    const ERC721 = await ethers.getContractFactory("MockERC721");
    const nftInstance = await ERC721.deploy();
    //const nftInstance = await ERC721.attach("0x0e1CaDc29Adaf24D2EbE68319951CAA954871d0E");
    console.log("ERC721 Address", nftInstance.address);

    await nftInstance.awardItem(accounts[0], "QmP96tpWTvT1wqpacYWZ9u19Pi61ME3BKuE8t1bckJz6Mf");
    await nftInstance.awardItem(accounts[0], "QmP96tpWTvT1wqpacYWZ9u19Pi61ME3BKuE8t1bckJz6Mf");
    // await nftInstance.awardItem(accounts[0], "QmP96tpWTvT1wqpacYWZ9u19Pi61ME3BKuE8t1bckJz6Mf");
    console.log("Minted");

    //Reward ERC20

    const ERC20Reward = await ethers.getContractFactory("MockERC20Reward");
    const TokenInstanceERC20Reward = await ERC20Reward.deploy("1000000000000000000000000000");
    //const TokenInstanceERC20Reward = await ERC20Reward.attach("0x53134D15769b0161fCC1531a69c5CfCc428b0cf4");
    console.log("RewardToken ERC20", TokenInstanceERC20Reward.address);
    const rewardToken = TokenInstanceERC20Reward.address;

    //Perpetual Staking

    const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
    const perpetualStaking = await upgrades.deployProxy(PerpetualStaking, {initializer: "initialize"});
    // const perpetualStaking = await PerpetualStaking.attach("0x04013CB8543B22C84Cddcdd25B8678b9b2f71021");
    
    console.log("Perpetual Staking Proxy : ", perpetualStaking.address);

    //Treasury

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = Treasury.attach("0x9AdF2b96d57E4CEcD9f3C7efF22Ddc78Ebd4ECaB");
    //const treasury = await Treasury.deploy();
    console.log("Treasury address :", treasury.address);
    //await treasury.initialize(accounts[0]);

    //Pool ERC721
    await perpetualStaking.deployNewPool(nftInstance.address, 1675336104, 1675339704, 20, [rewardToken], [2]);
    await new Promise(res => setTimeout(res, 10000));
    const pools = await perpetualStaking.poolsDeployed();
    console.log("ERC721 pool address", pools[0]);

    // Transfer reward to the erc721 pool contract
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockERC20 = await MockERC20.attach(rewardToken);

    await mockERC20.transfer(pools[0], ethers.utils.parseUnits("10000", 18));

    //Admin functions for ERC721 pool

    const PoolERC721 = await ethers.getContractFactory("PoolERC721");
    const poolERC721 = await PoolERC721.attach(pools[0]);

    await poolERC721.updateTreasury(treasury.address);
    await poolERC721.updatePlatformFee(100);

    //Approve and Deposit
    const MockERC721 = await ethers.getContractFactory("MockERC721");
    const mockERC721 = await MockERC721.attach(nftInstance.address);
    await mockERC721.approve(pools[0], 0);
    await new Promise(res => setTimeout(res, 10000));
    await mockERC721.approve(pools[0], 1);
    console.log("approved");
    // await new Promise(res => setTimeout(res, 9000));
    await poolERC721.deposit(0);
    await new Promise(res => setTimeout(res, 10000));
    await poolERC721.deposit(1);
    console.log("deposited");
    await new Promise(res => setTimeout(res, 10000));
    console.log("done");
    const rewardAmount = await poolERC721.getReward(rewardToken, accounts[0], 1);
    const rewardAmount2 = await poolERC721.getReward(rewardToken, accounts[0], 2);
    console.log("rewardAmount", rewardAmount, rewardAmount2);
    await poolERC721.claimTokenReward(rewardToken);
    // await poolERC721.withdraw(0);
    // console.log("withdrawn");
    // await poolERC721.withdraw(1);


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })

// ERC721 Address 0xA9906e1aaE787D6E9C581b8d3AFc4C3a74c21612
// RewardToken ERC20 0x2B82c8602bfEfEd26A362bf6cAD24a5dF7B4F01f
// Perpetual Staking Proxy :  0xfd8c26d61DF5CAC19eDB37E3F8CA3E168C45d1cc
// Treasury address : 0x9AdF2b96d57E4CEcD9f3C7efF22Ddc78Ebd4ECaB
// ERC721 pool address 0x959d992d88D207D632da551a84aa69cEb9dDdb4e