const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { isAwaitExpression, ModuleKind } = require("typescript");

describe("Perpetual Staking", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshopt in every test.
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
        let initialSupply = 1000; initialSupply = initialSupply.toString();
        const mockERC20 = await MockERC20.deploy(ethers.utils.parseUnits(initialSupply, 18));

        const MockERC721 = await ethers.getContractFactory("MockERC721");
        const mockERC721 = await MockERC721.deploy();

        const PoolERC20 = await ethers.getContractFactory("PoolERC20");
        const PoolERC721 = await ethers.getContractFactory("PoolERC721");

        return { perpetualStaking, mockERC20, mockERC721, PoolERC20, PoolERC721, owner, otherAccount, treasury };
    }
    describe("Deploy New pool", function () {
        it("Should deploy ERC20 pool", async function () {
            const { perpetualStaking, mockERC20, PoolERC20, owner } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = await PoolERC20.attach(pools[0]);
            expect(await poolERC20.depositToken()).to.equal(mockERC20.address);
        })
        it("Should deploy ERC721 pool", async function () {
            const { perpetualStaking, mockERC721, PoolERC721, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC721 = await PoolERC721.attach(pools[0]);
            expect(await poolERC721.depositToken()).to.equal(mockERC721.address);
        })
    })
    describe("Pool functions", function () {
        it("Deposit in ERC20 pool", async function () {
            const { perpetualStaking, mockERC20, PoolERC20, owner, treasury } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = await PoolERC20.attach(pools[0]);
            await poolERC20.updateTreasury(treasury.address);
            await poolERC20.updatePlatformFee(100);
            await mockERC20.approve(poolERC20.address, amountToDeposit);
            await poolERC20.deposit(amountToDeposit);
            let depositDetails = await poolERC20.depositDetailsByID(owner.address, 0);
            expect(depositDetails[0]).to.equal(amountToDeposit);
            expect(depositDetails[2]).to.equal(await poolERC20.calculatePlatformFee(amountToDeposit));
        })
        it("withdraw in ERC20 pool", async function () {
            const { perpetualStaking, mockERC20, PoolERC20, owner, treasury } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = await PoolERC20.attach(pools[0]);
            await poolERC20.updateTreasury(treasury.address);
            await poolERC20.updatePlatformFee(100);
            await mockERC20.approve(poolERC20.address, amountToDeposit);
            // await mockERC20.approve(poolERC20.address, amountToDeposit);
            await poolERC20.deposit(amountToDeposit);
            // We can increase the time in Hardhat Network
            await time.increaseTo(await time.latest() + 60);
            await poolERC20.withdraw(amountToDeposit + 1E18);
            let depositDetails = await poolERC20.depositDetailsByID(owner.address, 0);
            expect(depositDetails[0]).to.equal(0);
            expect(((ethers.utils.parseUnits("1000", 18)) - await poolERC20.calculatePlatformFee(amountToDeposit)).toString()).to.equal(await mockERC20.balanceOf(owner.address));
        })
        // it("Deposit in ERC721 pool", async function () {
        //     const { perpetualStaking, mockERC721, PoolERC721, mockERC20, owner } = await loadFixture(
        //         deployState
        //     );
        //     await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
        //     const pools = await perpetualStaking.poolsDeployed();
        //     const poolERC721 = await PoolERC721.attach(pools[0]);
        //     await mockERC721.awardItem(owner.address, "https://game.io");
        //     await mockERC721.approve(poolERC721.address, 0);
        //     await poolERC721.deposit(0);
        //     let depositDetails = await poolERC721.depositDetailsByID(owner.address, 1);
        //     expect(depositDetails[0]).to.equal(0);
        // })
        // it("Withdraw in ERC721 pool", async function () {
        //     const { perpetualStaking, mockERC721, PoolERC721, owner, mockERC20 } = await loadFixture(
        //         deployState
        //     );
        //     await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
        //     const pools = await perpetualStaking.poolsDeployed();
        //     const poolERC721 = await PoolERC721.attach(pools[0]);
        //     await mockERC721.awardItem(owner.address, "https://game.io");
        //     await mockERC721.approve(poolERC721.address, 0);
        //     await poolERC721.deposit(0);
        //     await poolERC721.withdraw(0);
        //     let depositDetails = await poolERC721.depositDetailsByID(owner.address, 1);
        //     expect(depositDetails[0]).to.equal(0);
        // })
        // it("Should break the loop on first check", async function () {
        //     const { perpetualStaking, mockERC20, PoolERC20, owner } = await loadFixture(
        //         deployState
        //     );
        //     let amountToDeposit = 10;
        //     amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
        //     await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
        //     const pools = await perpetualStaking.poolsDeployed();
        //     const poolERC20 = await PoolERC20.attach(pools[0]);
        //     await mockERC20.approve(poolERC20.address, amountToDeposit + amountToDeposit);
        //     await poolERC20.deposit(amountToDeposit);
        //     // We can increase the time in Hardhat Network
        //     await time.increaseTo(await time.latest() + 30);
        //     await poolERC20.deposit(amountToDeposit);
        //     await time.increaseTo(await time.latest() + 30);
        //     await poolERC20.deposit(amountToDeposit);

        //     await poolERC20.withdraw(amountToDeposit + 1E18);
        //     let depositDetails = await poolERC20.depositDetailsByID(owner.address, 1);
        //     expect(depositDetails[0]).to.equal(0);
        //     expect(ethers.utils.parseUnits("1000", 18)).to.equal(await mockERC20.balanceOf(owner.address));
        // })
        // it("Should withdraw partial - ERC20", async function () {
        //     const { perpetualStaking, mockERC20, PoolERC20, owner } = await loadFixture(
        //         deployState
        //     );
        //     let amountToDeposit = 10;
        //     amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
        //     await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
        //     const pools = await perpetualStaking.poolsDeployed();
        //     const poolERC20 = await PoolERC20.attach(pools[0]);
        //     await mockERC20.approve(poolERC20.address, amountToDeposit + amountToDeposit);
        //     await poolERC20.deposit(amountToDeposit);
        //     await poolERC20.deposit(amountToDeposit);
        //     await poolERC20.withdraw(ethers.utils.parseUnits("11", 18));
        //     let depositDetails = await poolERC20.depositDetailsByID(owner.address, 1);
        //     expect(depositDetails[0]).to.equal(0);
        //     let depositDetails1 = await poolERC20.depositDetailsByID(owner.address, 2);
        //     expect(depositDetails1[0]).to.equal(ethers.utils.parseUnits("9", 18))
        // })
        it("Should claim rewards and withdraw in ERC20 Pool", async function () {
            const { perpetualStaking, mockERC20, PoolERC20, owner, otherAccount,treasury } = await loadFixture(
                deployState
            );
            let amountToDeposit = 20;
            let amountToClaim = 100;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            amountToClaim = ethers.utils.parseUnits(amountToClaim.toString(), 18);
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [1]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = PoolERC20.attach(pools[0]);
            await poolERC20.updateTreasury(treasury.address);
            await poolERC20.updatePlatformFee(100);
            await mockERC20.approve(poolERC20.address, amountToDeposit + amountToDeposit);
            await poolERC20.deposit(amountToDeposit);

            await mockERC20.transfer(otherAccount.address, ethers.utils.parseUnits("20", 18));
            await mockERC20.connect(otherAccount).approve(poolERC20.address, amountToDeposit);
            await poolERC20.connect(otherAccount).deposit(amountToDeposit);
            console.log(await poolERC20.depositDetailsByID(owner.address, 0));
            console.log(await poolERC20.depositDetailsByID(otherAccount.address, 0));
            console.log("User deposit", await poolERC20.userDeposit(owner.address));
            expect(Number(await poolERC20.userDeposit(owner.address))).to.equal(Number(amountToDeposit) - await poolERC20.calculatePlatformFee(amountToDeposit))
            expect(await poolERC20.getRewardPerUnitOfDeposit(mockERC20.address)).to.equal(1);
            await mockERC20.transfer(poolERC20.address, amountToClaim);
            console.log("Accrued Reward erc20", await poolERC20.accruedReward(owner.address));
            console.log("Accrued Reward erc20 other", await poolERC20.accruedReward(otherAccount.address));
            console.log("count", await poolERC20.userDepositCount(owner.address));
            console.log("count other", await poolERC20.userDepositCount(otherAccount.address));
            await poolERC20.claimAllReward();
            await poolERC20.withdraw(ethers.utils.parseUnits("11", 18));
            console.log("claimed", await poolERC20.totalClaimed(mockERC20.address));
            expect(await poolERC20.totalClaimed(mockERC20.address)).to.equal(amountToClaim);
            console.log("totalDeposit", await poolERC20.totalDeposit());
            console.log("rewardToken by index", await poolERC20.rewardToken(0));
            console.log("rewardTokenCount", await poolERC20.rewardTokenCount());
            console.log("userClaimed", await poolERC20.userClaimed(owner.address, mockERC20.address));
            console.log("userTotalWithdrawl", await poolERC20.userTotalWithdrawl(owner.address));
            console.log("User deposit", await poolERC20.userDeposit(owner.address));
            console.log("User deposit - other", await poolERC20.userDeposit(otherAccount.address));
            console.log("getReward", await poolERC20.getReward(mockERC20.address, otherAccount.address, 1));
            console.log("Accrued Reward erc20 other", await poolERC20.accruedReward(otherAccount.address));
        })
        // it("should claim reward in ERC721 pool", async function () {
        //     const { perpetualStaking, mockERC721, mockERC20, PoolERC721, owner } = await loadFixture(
        //         deployState
        //     );
        //     let amountToClaim = 22;
        //     amountToClaim = ethers.utils.parseUnits(amountToClaim.toString(), 18);
        //     await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
        //     const pools = await perpetualStaking.poolsDeployed();
        //     const poolERC721 = await PoolERC721.attach(pools[0]);
        //     await mockERC721.awardItem(owner.address, "https://game.io");
        //     await mockERC721.awardItem(owner.address, "https://game.io");
        //     await mockERC721.awardItem(owner.address, "https://game.io");
        //     await mockERC721.approve(poolERC721.address, 0);
        //     await mockERC721.approve(poolERC721.address, 1);
        //     await poolERC721.deposit(0);
        //     await poolERC721.deposit(1);
        //     // We can increase the time in Hardhat Network
        //     await time.increaseTo(await time.latest() + 3);
        //     console.log(await poolERC721.userDepositCount(owner.address));
        //     console.log(await poolERC721.userDeposit(owner.address));
        //     expect(await poolERC721.getRewardPerUnitOfDeposit(mockERC20.address)).to.equal(2);
        //     console.log("get reward of 2", await poolERC721.getReward(mockERC20.address, owner.address, 1));
        //     console.log("Accrued Reward", await poolERC721.accruedReward(owner.address, mockERC20.address));
        //     await mockERC20.transfer(poolERC721.address, amountToClaim);
        //     await poolERC721.claimAllReward();
        //     expect(await poolERC721.claimed(mockERC20.address)).to.equal(amountToClaim);
        // })
    });
});
