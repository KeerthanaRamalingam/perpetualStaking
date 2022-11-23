// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPerpetualStaking.sol";

// import "hardhat/console.sol";

contract PoolERC721 is Ownable, ReentrancyGuard, ERC721Holder {
    //Pool Maturity date: This is the date on which contract will stop accepting fresh deposits and will also stop accruing the rewards.
    // Can be reinitialised
    uint256 private _maturityDate;

    //Pool Start date: the date from which contract will start to accept the assets
    uint256 private immutable _startDate;

    //Cliff: This is the lock-in period until which deposit assets cannot be withdrawn.
    uint256 private immutable _cliff;

    //PlatformFee: For ERC20, For each deposit, the platform may deduct fees.
    uint256 private _platformFee;

    // Treasury to maintain platform fee
    address private _treasury;

    //Maintain reward for each tokens
    address[] private rewardTokens;

    //Deposit token used to create this contract
    address private _depositToken;

    //Claimed rewards
    mapping(address => uint256) private _claimed;

    struct Deposit {
        uint256 depositBalance;
        uint256 depositTime;
    }
    //Maintain multiple deposits of users
    mapping(address => mapping(uint256 => Deposit)) private userDeposits;

    //Maintain user pool count
    mapping(address => uint256) private userPoolCount;

    mapping(address => uint256) private rewardForDeposit;

    //Withdraw state catch
    event Withdraw(address tokenAddress, uint256 amount);

    // Event to record reinitilaized maturityDate
    event MaturityDate(uint256 updatedMaturityDate);

    // Event to record reinitilized platform fee
    event PlatformFee(uint256 platformFee);

    // Event to record updated reward amount of each token
    event RewardForTokens(uint256[] reward, address[] tokenAddress);

    //Claim state catch
    event Claim(address tokenAddress, uint256 amount);

    constructor(
        address depositToken_,
        uint256 startDate_,
        uint256 maturityDate_,
        uint256 cliff_,
        address owner_,
        address[] memory rewardTokens_,
        uint256[] memory rewardUnits_
    ) {
        _depositToken = depositToken_;

        // Cannot be initialized again.
        // State of this variable remain same across functions
        _startDate = startDate_;
        _maturityDate = maturityDate_;
        _cliff = cliff_;
        updateRewardForToken(rewardUnits_, rewardTokens_);
        transferOwnership(owner_);
    }

    // update reward for tokens
    function updateRewardForToken(
        uint256[] memory newReward,
        address[] memory tokenAddress
    ) internal {
        rewardTokens = tokenAddress;
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            rewardForDeposit[tokenAddress[i]] = newReward[i];
        }
        emit RewardForTokens(newReward, tokenAddress);
    }

    modifier isExpired() {
        require(block.timestamp > _startDate);
        require(block.timestamp < maturityDate());
        _;
    }

    function deposit(uint256 nftID) external nonReentrant isExpired {
        require(
            IERC721(_depositToken).ownerOf(nftID) == msg.sender,
            "You are not the Owner"
        );
        userPoolCount[msg.sender]++;
        userDeposits[msg.sender][userPoolCount[msg.sender]] = Deposit(
            nftID,
            block.timestamp
        );
        IERC721(_depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            nftID,
            ""
        );
    }

    // -------------------- CLAIM ALL TOKEN REWARD IN ONE GO (NO INPUT) ----------------------------- //
    // -------------------- ONE WITHOUT AMOUNT ----------------------//
    // Function to claim Rewards
    // Reward Can be claimed only after cliff
    function claimWithTokenAndAmount(address tokenAddress, uint256 amount)
        external
    {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                unclaimed = getReward(tokenAddress, msg.sender, i);
            }
        }
        require(unclaimed >= amount, "Trying to claim more than alloted");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Insufficient reward balance in contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, amount);
        _claimed[tokenAddress] = amount;
        emit Claim(tokenAddress, amount);
    }

    function claimWithToken(address tokenAddress) external {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                unclaimed = getReward(tokenAddress, msg.sender, i);
            }
        }
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= unclaimed,
            "Insufficient reward balance in contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, unclaimed);
        _claimed[tokenAddress] = unclaimed;
        emit Claim(tokenAddress, unclaimed);
    }

    function claimAllReward() external {
        uint256 unclaimed;
        for (uint256 j = 0; j < rewardTokens.length; j++) {
            for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
                if (
                    _cliff < 0 ||
                    block.timestamp >
                    userDeposits[msg.sender][i].depositTime + _cliff
                ) unclaimed += getReward(rewardTokens[j], msg.sender, i);
            }
            require(
                IERC20(rewardTokens[j]).balanceOf(address(this)) >= unclaimed,
                "Insufficient reward balance in contract"
            );
            IERC20(rewardTokens[j]).transfer(msg.sender, unclaimed);
            _claimed[rewardTokens[j]] += unclaimed;
            emit Claim(rewardTokens[j], unclaimed);
        }
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, maturityDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(
        address tokenAddress,
        address user,
        uint256 depositID
    ) public view returns (uint256 lastReward) {
        uint256 rewardCount = getRewardPerUnitOfDeposit(tokenAddress) *
            10**IERC20Metadata(tokenAddress).decimals(); // * userDeposits[user][depositID].depositBalance;
        lastReward =
            lastReward +
            (((lastTimeRewardApplicable() -
                userDeposits[user][depositID].depositTime) * rewardCount) -
                _claimed[tokenAddress]);
    }

    function accruedReward(address userAddress, address rewardTokenAddress)
        public
        view
        returns (uint256 rewardAmount)
    {
        for (uint256 i = 1; i <= userPoolCount[userAddress]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                rewardAmount += getReward(rewardTokenAddress, msg.sender, i);
            }
        }
    }

    // Withdraw deposit amount without reward
    // Withdraw happens only after cliff
    // Reward should be claimed seperately After cliff
    function withdraw(uint256 nftID) external {
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                if (userDeposits[msg.sender][i].depositBalance == nftID) {
                    IERC721(_depositToken).safeTransferFrom(
                        address(this),
                        msg.sender,
                        nftID,
                        ""
                    );
                    delete userDeposits[msg.sender][i];
                    emit Withdraw(_depositToken, nftID);
                }
            }
        }
    }

    function getRewardPerUnitOfDeposit(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return rewardForDeposit[tokenAddress];
    }

    // return start date of the pool
    function startDate() public view returns (uint256) {
        return _startDate;
    }

    // return maturity date of the pool
    function maturityDate() public view returns (uint256) {
        return _maturityDate;
    }

    // return cliff of the pool
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    // Reassigning maturity Date
    // checks Ownership and internal call
    function updateMaturityDate(uint256 newMaturityDate) external onlyOwner {
        _updateMaturityDate(newMaturityDate);
    }

    // safe Internal call to update MaturityDate
    function _updateMaturityDate(uint256 maturitydate_) internal {
        _maturityDate = maturitydate_;
        emit MaturityDate(_maturityDate);
    }

    // Reassigning platform Fee
    // checks Ownership and internal call
    function updatePlatformFee(uint256 newPlatformFee) external onlyOwner {
        _updatePlatformFee(newPlatformFee);
    }

    // safe Internal call to update MaturityDate
    function _updatePlatformFee(uint256 platformFee_) internal {
        _platformFee = platformFee_;
        emit PlatformFee(_platformFee);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function updateTreasuryContract(address _treasuryContract)
        external
        onlyOwner
    {
        require(isContract(_treasuryContract), "Address is not a contract");
        _treasury = _treasuryContract;
    }

    function treasuryContract() public view returns (address) {
        return _treasury;
    }

    function depositToken() public view returns (address) {
        return _depositToken;
    }

    function claimed(address tokenAddress) public view returns (uint256) {
        return _claimed[tokenAddress];
    }

    function depositDetailsByID(address userAddress, uint256 depositID)
        public
        view
        returns (Deposit memory depositdetails)
    {
        return userDeposits[userAddress][depositID];
    }

    function userDepositCount(address userAddress)
        public
        view
        returns (uint256)
    {
        return userPoolCount[userAddress];
    }

    function userDeposit(address userAddress)
        public
        view
        returns (uint256 balance)
    {
        for (uint256 i = 1; i <= userPoolCount[userAddress]; i++) {
            balance += 1;
        }
    }
}
