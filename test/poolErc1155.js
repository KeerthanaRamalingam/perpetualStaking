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
        
        const PerpetualStaking = await ethers.getContractFactory("PerpetualErc1155");
        const perpetualStaking = await PerpetualStaking.deploy();
        await perpetualStaking.initialize();

        const Treasury = await ethers.getContractFactory("Treasury");
        const treasury = await Treasury.deploy();
        await treasury.initialize(owner.address);


        const MockERC20 = await ethers.getContractFactory("MockERC20");
        let initialSupply = 10000000; 
        initialSupply = initialSupply.toString();
        const mockERC20 = await MockERC20.deploy(ethers.utils.parseUnits(initialSupply,18));

        const MockERC1155 = await ethers.getContractFactory("MockERC1155");
        const mockERC1155 = await MockERC1155.deploy();

        const PoolERC1155 = await ethers.getContractFactory("PoolERC1155");

        return {perpetualStaking, mockERC20, mockERC1155, PoolERC1155, owner, otherAccount, treasury};

    }

    // describe("Deploy New pool", function() {
    //     it("Should deploy ERC1155 pool", async function() {
    //         const { perpetualStaking, mockERC1155, PoolERC1155, owner, mockERC20 } = await loadFixture(
    //             deployState
    //         );
    //         await perpetualStaking.deployNewPool(mockERC1155.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
    //         const pools = await perpetualStaking.poolsDeployed();
    //         console.log("pools", pools);
    //         const poolERC1155 = await PoolERC1155.attach(pools[0]);
    //         expect(await poolERC1155.depositToken()).to.equal(mockERC1155.address);
    //     });
    // });

    describe("Pool functions", function() {
        it("Deposit in ERC1155 pool", async function() {
            const { perpetualStaking, mockERC1155, PoolERC1155, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC1155.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC1155 = await PoolERC1155.attach(pools[0]);
            await mockERC1155.setApprovalForAll(poolERC1155.address, true);

            await poolERC1155.deposit(2, 1);

            let depositDetails = await poolERC1155.depositDetailsByID(owner.address, 1);
            expect(depositDetails[0]).to.equal(1);

        });

        it("Claim Reward", async function() {
            const {perpetualStaking, mockERC1155,PoolERC1155, owner, mockERC20 } = await loadFixture(
                deployState
            );

            await perpetualStaking.deployNewPool(mockERC1155.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [1]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC1155 = await PoolERC1155.attach(pools[0]);

            await mockERC1155.setApprovalForAll(poolERC1155.address, true);

            await poolERC1155.deposit(0, 1000000);
            expect(await poolERC1155.userDepositCount(owner.address)).to.equal(1);
            console.log("User deposited count ", await poolERC1155.userDepositCount(owner.address));
            console.log("Reward units ",await poolERC1155.getRewardPerUnitOfDeposit(mockERC20.address));
            console.log("Reward Amount ",await poolERC1155.getReward(mockERC20.address, owner.address, 1));
            await mockERC20.transfer(poolERC1155.address, "9000000000000000000000000");
            await poolERC1155.claimAllReward();
            console.log("claimed amount", await poolERC1155.userClaimed(owner.address, mockERC20.address));
            await poolERC1155.withdraw(0,1000);

        });

        it("Withdraw in ERC1155 pool", async function() {
            const { perpetualStaking, mockERC1155, PoolERC1155, owner, mockERC20 } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC1155.address, await time.latest() - 60, await time.latest() + 240, 0, [mockERC20.address], [2]);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC1155 = await PoolERC1155.attach(pools[0]);

            await mockERC1155.setApprovalForAll(poolERC1155.address, true);

            await poolERC1155.deposit(2, 1);
            await mockERC20.transfer(poolERC1155.address, "9000000000000000000000000");
            console.log("Reward amount",await poolERC1155.getReward(mockERC20.address, owner.address, 1));

            //await poolERC1155.claimAllReward();
            await poolERC1155.claimTokenReward(mockERC20.address);
            await poolERC1155.withdraw(2,1);
        });

    })

})