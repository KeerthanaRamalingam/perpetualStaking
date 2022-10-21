const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { isAwaitExpression } = require("typescript");

describe("Perpetual Staking", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshopt in every test.
    async function deployState() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
        const perpetualStaking = await PerpetualStaking.deploy();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        let initialSupply = 100; initialSupply = initialSupply.toString();
        const mockERC20 = await MockERC20.deploy(ethers.utils.parseUnits(initialSupply, 18));

        const MockERC721 = await ethers.getContractFactory("MockERC721");
        const mockERC721 = await MockERC721.deploy();

        const Pool = await ethers.getContractFactory("PoolERC20");

        return { perpetualStaking, mockERC20, mockERC721, Pool, owner, otherAccount };
    }
    describe("Deploy New pool", function() {
        it("Should deploy ERC20 pool", async function () {
            const { perpetualStaking, mockERC20, Pool, owner } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = await Pool.attach(pools[0]);
            expect(await poolERC20.depositToken()).to.equal(mockERC20.address);
        })
        it("Should deploy ERC721 pool", async function () {
            const { perpetualStaking, mockERC721, Pool, owner } = await loadFixture(
                deployState
            );
            await perpetualStaking.deployNewPool(mockERC721.address, await time.latest() - 60, await time.latest() + 240, 0);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC721 = await Pool.attach(pools[0]);
            expect(await poolERC721.depositToken()).to.equal(mockERC721.address);
        })
    })
    describe("Pool functions", function() {
        it("Deposit in ERC20 pool", async function() {
            const { perpetualStaking, mockERC20, Pool, owner } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = await Pool.attach(pools[0]);
            await mockERC20.approve(poolERC20.address, amountToDeposit);
            await poolERC20.deposit(amountToDeposit);
            let depositDetails = await poolERC20.userDeposit(owner.address, 1);
            expect(depositDetails[0]).to.equal(amountToDeposit);
        })
        it("withdraw in ERC20 pool", async function() {
            const { perpetualStaking, mockERC20, Pool, owner } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            await perpetualStaking.deployNewPool(mockERC20.address, await time.latest() - 60, await time.latest() + 240, 0);
            const pools = await perpetualStaking.poolsDeployed();
            const poolERC20 = await Pool.attach(pools[0]);
            await mockERC20.approve(poolERC20.address, amountToDeposit);
            await poolERC20.deposit(amountToDeposit);
            await poolERC20.withdraw(amountToDeposit+1E18);
            let depositDetails = await poolERC20.userDeposit(owner.address, 1);
            console.log(depositDetails);
            expect(depositDetails[0]).to.equal(0);
            expect(ethers.utils.parseUnits("100", 18)).to.equal(await mockERC20.balanceOf(owner.address));
        })
    });
});