const { ethers } = require("hardhat");

async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log("Accounts: ", accounts[0]);

    //Attach buddy Contract
    const buddy = await ethers.getContractFactory("BuddyV5");
    const buddyInstance = await buddy.attach("0x9882224b64aF861bA8932d38e3317B2cB4662c21");
    console.log("ERC721 Address", buddyInstance.address);

    //drops collectionContract to whitelist
    const collectionAddress = "0xCA9688DB110B57C3b2a47037773c2f92Df6C086e";

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
    // const treasury = Treasury.attach("0xcEC2AE16554988161CE6f4D6ded616B845a4baB9");
    const treasury = await Treasury.deploy();
    console.log("Treasury address :", treasury.address);
    await treasury.initialize(accounts[0]);

    //Pool ERC721
    await perpetualStaking.deployNewPool(buddyInstance.address, 1675247054, 1675254254, 20, [rewardToken], [2]);
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

    await poolERC721.dropsCollection(collectionAddress);

    const tokenId = 137;
    
    //Approve
    await buddyInstance.approve(pools[0], tokenId);
    await new Promise(res => setTimeout(res, 10000));
    console.log("approved");
    
    //Deposit
    await poolERC721.deposit(tokenId);
    await new Promise(res => setTimeout(res, 10000));
    console.log("deposited");
    
    //reward
    const rewardAmount = await poolERC721.getReward(rewardToken, accounts[0], 1);
    console.log("rewardAmount", rewardAmount);
    await poolERC721.claimTokenReward(rewardToken);
    
    
    //withdraw
    // await poolERC721.withdraw(tokenId);
    // console.log("withdrawn");


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })

// ERC721 Address 0x9882224b64aF861bA8932d38e3317B2cB4662c21
// RewardToken ERC20 0x7BbBB7f2bb8dD39ca11683A28d8b27B3D23E42c9
// Perpetual Staking Proxy :  0xe5FfDa21D534167D986cf3A69A7bE2b8Db4024DA
// Treasury address : 0x9AdF2b96d57E4CEcD9f3C7efF22Ddc78Ebd4ECaB
// ERC721 pool address 0x04E1cF701c758bB66672e7F8fA2c111383862A68