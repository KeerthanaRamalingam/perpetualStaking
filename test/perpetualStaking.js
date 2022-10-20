const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("Perpetual Staking", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshopt in every test.
    async function deployState() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        const PerpetualStaking = await ethers.getContractFactory("PerpetualStaking");
        const perpetualStaking = await PerpetualStaking.deploy(await time.latest() - 60, await time.latest() + 300, 0);

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        let initialSupply = 100; initialSupply = initialSupply.toString();
        const mockERC20 = await MockERC20.deploy(ethers.utils.parseUnits(initialSupply, 18));

        const MockERC721 = await ethers.getContractFactory("MockERC721");
        const mockERC721 = await MockERC721.deploy();

        const MockERC1155 = await ethers.getContractFactory("MockERC1155");
        const mockERC1155 = await MockERC1155.deploy();

        const MockReward = await ethers.getContractFactory("MockERC20");
        let rewardSupply = 100; rewardSupply = rewardSupply.toString();
        const mockReward = await MockReward.deploy(ethers.utils.parseUnits(rewardSupply, 18));

        const Pool = await ethers.getContractFactory("Pool");

        return { perpetualStaking, mockERC20, mockERC721, mockERC1155, mockReward, Pool, owner, otherAccount };
    }

    describe("Deposit", function () {
        it("Should set cliff correctly", async function () {
            const { perpetualStaking } = await loadFixture(
                deployState
            );
            expect(await perpetualStaking.cliff()).to.equal(0);
        })
        it("Should accept ERC20 for deposit", async function () {
            const { perpetualStaking, mockERC20, owner } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            await mockERC20.approve(perpetualStaking.address, amountToDeposit);
            await perpetualStaking.deposit(mockERC20.address, amountToDeposit, 0);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC20.balanceOf(ownerPool)).to.equal(amountToDeposit);
        })
        it("Should accept ERC721 for deposit", async function () {
            const { perpetualStaking, mockERC721, owner } = await loadFixture(
                deployState
            );
            await mockERC721.awardItem(owner.address, "https://game.io");
            expect(await mockERC721.ownerOf(0)).to.equal(owner.address);
            await mockERC721.approve(perpetualStaking.address, 0);
            await perpetualStaking.deposit(mockERC721.address, 0, 0);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC721.ownerOf(0)).to.equal(ownerPool);
        })
        it("Should accept ERC1155(ERC20) for deposit", async function () {
            const { perpetualStaking, mockERC1155, owner } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            let batchID = 1;
            await mockERC1155.setApprovalForAll(perpetualStaking.address, true);
            expect(await mockERC1155.isApprovedForAll(owner.address, perpetualStaking.address)).to.equal(true);
            await perpetualStaking.deposit(mockERC1155.address, amountToDeposit, batchID);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC1155.balanceOf(ownerPool, batchID)).to.equal(amountToDeposit);
        })
        it("Should accept ERC1155(ERC721) for deposit", async function () {
            const { perpetualStaking, mockERC1155, owner } = await loadFixture(
                deployState
            );
            let NFT_ID_Deposit = 1;
            let batchID = 2;
            await mockERC1155.setApprovalForAll(perpetualStaking.address, true);
            expect(await mockERC1155.isApprovedForAll(owner.address, perpetualStaking.address)).to.equal(true);
            await perpetualStaking.deposit(mockERC1155.address, NFT_ID_Deposit, batchID);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC1155.balanceOf(ownerPool, batchID)).to.equal(NFT_ID_Deposit);
        })
        it("Should set reward amount for each token", async function () {
            const { perpetualStaking, mockReward, owner } = await loadFixture(
                deployState
            );
            await perpetualStaking.updateRewardForToken(2, mockReward.address);
            expect(await perpetualStaking.getRewardOfToken(mockReward.address)).to.equal(2);
        })
        it("Should withdraw ERC20 from pool", async function () {
            const { perpetualStaking, mockERC20, Pool, owner } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            await mockERC20.approve(perpetualStaking.address, amountToDeposit);
            await perpetualStaking.deposit(mockERC20.address, amountToDeposit, 0);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            const pool = await Pool.attach(ownerPool)
            await pool.withdraw();
            expect(await mockERC20.balanceOf(ownerPool)).to.equal(0);
            expect(await mockERC20.balanceOf(owner.address)).to.equal(ethers.utils.parseUnits("100", 18));
        })
        it("Should Withdraw ERC721 from pool", async function () {
            const { perpetualStaking, mockERC721, Pool, owner } = await loadFixture(
                deployState
            );
            await mockERC721.awardItem(owner.address, "https://game.io");
            expect(await mockERC721.ownerOf(0)).to.equal(owner.address);
            await mockERC721.approve(perpetualStaking.address, 0);
            await perpetualStaking.deposit(mockERC721.address, 0, 0);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC721.ownerOf(0)).to.equal(ownerPool);
            const pool = await Pool.attach(ownerPool)
            await pool.withdraw();
            expect(await mockERC721.ownerOf(0)).to.equal(owner.address);
        })
        it("Should withdraw ERC1155(ERC20) from pool", async function () {
            const { perpetualStaking, mockERC1155, Pool, owner } = await loadFixture(
                deployState
            );
            let amountToDeposit = 10;
            amountToDeposit = ethers.utils.parseUnits(amountToDeposit.toString(), 18);
            let batchID = 1;
            await mockERC1155.setApprovalForAll(perpetualStaking.address, true);
            expect(await mockERC1155.isApprovedForAll(owner.address, perpetualStaking.address)).to.equal(true);
            await perpetualStaking.deposit(mockERC1155.address, amountToDeposit, batchID);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC1155.balanceOf(ownerPool, batchID)).to.equal(amountToDeposit);
            const pool = await Pool.attach(ownerPool)
            await pool.withdraw();
            expect(await mockERC1155.balanceOf(owner.address, batchID)).to.equal(ethers.utils.parseUnits("1", 27));
        })
        it("should withdraw ERC1155(ERC721) from pool", async function () {
            const { perpetualStaking, mockERC1155, owner, Pool } = await loadFixture(
                deployState
            );
            let NFT_ID_Deposit = 1;
            let batchID = 2;
            await mockERC1155.setApprovalForAll(perpetualStaking.address, true);
            expect(await mockERC1155.isApprovedForAll(owner.address, perpetualStaking.address)).to.equal(true);
            await perpetualStaking.deposit(mockERC1155.address, NFT_ID_Deposit, batchID);
            let ownerPool = await perpetualStaking.userPools(owner.address, 0);
            expect(await mockERC1155.balanceOf(ownerPool, batchID)).to.equal(NFT_ID_Deposit);
            const pool = await Pool.attach(ownerPool)
            await pool.withdraw();
            expect(await mockERC1155.balanceOf(owner.address, batchID)).to.equal(NFT_ID_Deposit);
        })
    })

})