const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Perpetual Staking", function () {

    async function deployState() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        
        const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
        const perpetualStaking = await PerpetualStaking.deploy();
        await perpetualStaking.initialize();

        const Treasury = await ethers.getContractFactory("Treasury");
        const treasury = await Treasury.deploy();
        await treasury.initialize(owner.address);


        const MockERC20 = await ethers.getContractFactory("MockERC20");
        let initialSupply = 1000; 
        initialSupply = initialSupply.toString();
        const mockERC20 = await MockERC20.deploy(ethers.utils.parseUnits(initialSupply,18));

        const MockERC721 = await ethers.getContractFactory("MockERC721");
        const mockERC721 = await MockERC721.deploy();

        const PoolERC20 = await ethers.getContractFactory("PoolERC20");
        const PoolERC721 = await ethers.getContractFactory("PoolERC721");

        return {perpetualStaking, mockERC20, mockERC721, PoolERC20, PoolERC721, owner, otherAccount, treasury};

    }

    describe("Deploy New pool", function() {
        it("Should deploy ERC721 pool", async function() {
            const { perpetualStaking, mockERC721, PoolERC721, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC721 = await PoolERC721.attach(pools[0]);
            expect(await poolERC721.depositToken()).to.equal(mockERC721.address);
        });
    });

    describe("Pool functions", function() {   
        it("Deposit in ERC721 pool", async function() {
            const { perpetualStaking, mockERC721, PoolERC721, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC721 = await PoolERC721.attach(pools[0]);

            await mockERC721.awardItem(owner.address, "https://game.io");
            await mockERC721.approve(poolERC721.address, 0);
            
            await poolERC721.deposit(0);

            let depositDetails = await poolERC721.depositDetailsByID(owner.address, 1);
            expect(depositDetails[0]).to.equal(0);
        });

        it("Claim Reward ", async function() {
            const { perpetualStaking, mockERC721, PoolERC721, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC721 = await PoolERC721.attach(pools[0]);

            await mockERC721.awardItem(owner.address, "https://game.io");
            await mockERC721.awardItem(owner.address, "https://game.io");
            await mockERC721.approve(poolERC721.address, 0);
            await mockERC721.approve(poolERC721.address, 1);
            
            await poolERC721.deposit(0);
            await poolERC721.deposit(1);
            //await time.increaseTo(await time.latest() + 100);

            expect(await poolERC721.userDepositCount(owner.address)).to.equal(2);
            console.log("User Deposited count", await poolERC721.userDepositCount(owner.address));
            expect(await poolERC721.userDepositCount(owner.address)).to.equal(2);
            console.log("Reward Units ",await poolERC721.getRewardPerUnitOfDeposit(mockERC20.address));
            console.log("Reward Amount ",await poolERC721.getReward(mockERC20.address, owner.address, 1));
            await mockERC20.transfer(poolERC721.address, "20000000000000000000");
            console.log("Reward balance in contract", await mockERC20.balanceOf(poolERC721.address));
            await poolERC721.claimAllReward();
            await poolERC721.withdraw(0);
            await poolERC721.withdraw(1);

        });

        it("Withdraw in ERC721 pool", async function() {
            const { perpetualStaking, mockERC721, PoolERC721, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC721 = await PoolERC721.attach(pools[0]);

            await mockERC721.awardItem(owner.address, "https://game.io");
            await mockERC721.approve(poolERC721.address, 0);
            
            await poolERC721.deposit(0);
            console.log("Reward Amount ",await poolERC721.getReward(mockERC20.address, owner.address, 1));
            await mockERC20.transfer(poolERC721.address, "20000000000000000000");
            console.log("Reward balance in contract", await mockERC20.balanceOf(poolERC721.address));
            await poolERC721.claimAllReward();
            await poolERC721.withdraw(0);
        });
    });

})
