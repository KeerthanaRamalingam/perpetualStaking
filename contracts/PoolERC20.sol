// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPerpetualStaking.sol";

import "hardhat/console.sol";

contract PoolERC20 is Ownable, ReentrancyGuard {
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
    address[] private _rewardTokens;

    //Deposit token used to create this contract
    address private _depositToken;

    //total deposit
    uint256 private _totalDeposit;

    //Claimed rewards
    mapping(address => uint256) private _claimed;

    mapping(address => mapping(address => uint256)) private _userClaimed;

    mapping(address => uint256) private _userTotalWithdrawl;

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

    // --------- FIX REWARD TOKEN WITH ITS VALUE AS WELL - NO UPDATE -----------//
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
        _rewardTokens = tokenAddress;
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            rewardForDeposit[tokenAddress[i]] = newReward[i];
        }
        emit RewardForTokens(newReward, tokenAddress);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    modifier isExpired() {
        require(block.timestamp > _startDate);
        require(block.timestamp < endDate());
        _;
    }

    ///@notice Users deposit "Deposit token" to the pool
    ///@param amount Amount of token to deposit
    function deposit(uint256 amount) external nonReentrant isExpired {
        require(
            IERC20(_depositToken).balanceOf(msg.sender) >= amount,
            "You are not the Owner"
        );
        userPoolCount[msg.sender]++;
        _totalDeposit += amount;
        userDeposits[msg.sender][userPoolCount[msg.sender]] = Deposit(
            amount,
            block.timestamp
        );
        IERC20(_depositToken).transferFrom(msg.sender, address(this), amount);
    }

    // -------------------- CLAIM ALL TOKEN REWARD IN ONE GO (NO INPUT) ----------------------------- //
    // -------------------- ONE WITHOUT AMOUNT ----------------------//
    // Function to claim Rewards
    // Reward Can be claimed only after cliff
    // function claimWithTokenAndAmount(address rewardTokenAddress, uint256 amount)
    //     external
    // {
    //     uint256 unclaimed;
    //     for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
    //         if (
    //             _cliff < 0 ||
    //             block.timestamp >
    //             userDeposits[msg.sender][i].depositTime + _cliff
    //         ) {
    //             unclaimed = getReward(rewardTokenAddress, msg.sender, i);
    //         }
    //     }
    //     // console.log("Unclaimed is %o", unclaimed);
    //     require(unclaimed >= amount, "Trying to claim more than alloted");
    //     require(
    //         IERC20(rewardTokenAddress).balanceOf(address(this)) >= amount,
    //         "Insufficient reward balance in contract"
    //     );
    //     IERC20(rewardTokenAddress).transfer(msg.sender, amount);
    //     _claimed[rewardTokenAddress] = amount;
    //     emit Claim(rewardTokenAddress, amount);
    // }

    function claimTokenReward(address rewardTokenAddress)
        external
        nonReentrant
    {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                unclaimed = getReward(rewardTokenAddress, msg.sender, i);
            }
        }
        require(
            IERC20(rewardTokenAddress).balanceOf(address(this)) >= unclaimed,
            "Insufficient reward balance in contract"
        );
        IERC20(rewardTokenAddress).transfer(msg.sender, unclaimed);
        _claimed[rewardTokenAddress] += unclaimed;
        _userClaimed[msg.sender][rewardTokenAddress] += unclaimed;
        emit Claim(rewardTokenAddress, unclaimed);
    }

    ///@notice Claim the total rewards from all reward tokens
    function claimAllReward() external nonReentrant {
        uint256 unclaimed;
        for (uint256 j = 0; j < _rewardTokens.length; j++) {
            for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
                if (
                    _cliff < 0 ||
                    block.timestamp >
                    userDeposits[msg.sender][i].depositTime + _cliff
                ) {
                    unclaimed += getReward(_rewardTokens[j], msg.sender, i);
                }
            }
            require(
                IERC20(_rewardTokens[j]).balanceOf(address(this)) >= unclaimed,
                "Insufficient reward balance in contract"
            );
            IERC20(_rewardTokens[j]).transfer(msg.sender, unclaimed);
            _claimed[_rewardTokens[j]] += unclaimed;
            _userClaimed[msg.sender][_rewardTokens[j]] += unclaimed;
            emit Claim(_rewardTokens[j], unclaimed);
        }
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, endDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(
        address tokenAddress,
        address user,
        uint256 depositID
    ) internal view returns (uint256 lastReward) {
        uint256 rewardCount = getRewardPerUnitOfDeposit(tokenAddress) *
            userDeposits[user][depositID].depositBalance;
        lastReward =
            lastReward +
            (((lastTimeRewardApplicable() -
                userDeposits[user][depositID].depositTime) * rewardCount) -
                _claimed[tokenAddress]);
    }

    function accruedReward(address userAddress)
        public
        view
        returns (uint256 rewardAmount)
    {
        for (uint256 j = 0; j < _rewardTokens.length; j++) {
            for (uint256 i = 1; i <= userPoolCount[userAddress]; i++) {
                if (
                    _cliff < 0 ||
                    block.timestamp >
                    userDeposits[msg.sender][i].depositTime + _cliff
                ) {
                    rewardAmount += getReward(_rewardTokens[j], msg.sender, i);
                }
            }
        }
    }

    // Withdraw deposit amount without reward
    // Withdraw happens only after cliff
    // Reward should be claimed seperately After cliff
    function withdraw(uint256 amount) external {
        uint256 pendingAmount = amount;
        uint256 failedCount;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (failedCount > 0) break;
            // Only after cliff
            if (
                cliff() < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                // console.log("Inside loop is %o", block.timestamp);
                // Commented for unit testing (implement block increase)
                // if first pool has greater amount than required, subract and do nothing
                if (
                    userDeposits[msg.sender][i].depositBalance > 0 &&
                    userDeposits[msg.sender][i].depositBalance >
                    pendingAmount &&
                    pendingAmount > 0
                ) {
                    IERC20(_depositToken).transfer(msg.sender, pendingAmount);
                    userDeposits[msg.sender][i].depositBalance -= pendingAmount;
                    _totalDeposit -= pendingAmount;
                    _userTotalWithdrawl[msg.sender] += pendingAmount;
                }
                // if first pool has lesser amount, subract the amount and save the remaining amount and delete the first pool
                else {
                    pendingAmount =
                        pendingAmount -
                        userDeposits[msg.sender][i].depositBalance;
                    _totalDeposit -= userDeposits[msg.sender][i].depositBalance;
                    _userTotalWithdrawl[msg.sender] += pendingAmount;
                    IERC20(_depositToken).transfer(
                        msg.sender,
                        userDeposits[msg.sender][i].depositBalance
                    );
                    delete userDeposits[msg.sender][i];
                }
                emit Withdraw(_depositToken, amount);
            } else {
                failedCount += 1;
            }
        }
    }

    function getRewardPerUnitOfDeposit(address rewardTokenAddress)
        public
        view
        returns (uint256)
    {
        return rewardForDeposit[rewardTokenAddress];
    }

    // return start date of the pool
    function startDate() public view returns (uint256) {
        return _startDate;
    }

    // return maturity date of the pool
    function endDate() public view returns (uint256) {
        return _maturityDate;
    }

    // return cliff of the pool
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    // Reassigning maturity Date
    // checks Ownership and internal call
    function updateEndDate(uint256 _endDate) external onlyOwner {
        _updateEndDate(_endDate);
    }

    // safe Internal call to update MaturityDate
    function _updateEndDate(uint256 endDate_) internal {
        _maturityDate = endDate_;
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

    function updateTreasury(address newContractAddress) external onlyOwner {
        require(isContract(newContractAddress), "Address is not a contract");
        _treasury = newContractAddress;
    }

    function platformFee() public view returns (uint256) {
        return _platformFee;
    }

    function treasury() public view returns (address) {
        return _treasury;
    }

    function depositToken() public view returns (address) {
        return _depositToken;
    }

    function depositDetailsByID(address userAddress, uint256 depositIndex)
        public
        view
        returns (Deposit memory depositdetails)
    {
        return userDeposits[userAddress][depositIndex];
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
        returns (uint256 depositAmount)
    {
        for (uint256 i = 1; i <= userPoolCount[userAddress]; i++) {
            depositAmount += userDeposits[userAddress][i].depositBalance;
        }
    }

    function totalDeposit() public view returns (uint256) {
        return _totalDeposit;
    }

    function rewardToken(uint256 rewardTokenIndex)
        public
        view
        returns (address)
    {
        return _rewardTokens[rewardTokenIndex];
    }

    function rewardTokenCount() public view returns (uint256) {
        return _rewardTokens.length;
    }

    function totalClaimed(address rewardTokenAddress)
        public
        view
        returns (uint256)
    {
        return _claimed[rewardTokenAddress];
    }

    function userClaimed(address userAddress, address rewardTokenAddress)
        public
        view
        returns (uint256)
    {
        return _userClaimed[userAddress][rewardTokenAddress];
    }

    function userTotalWithdrawl(address userAddress)
        public
        view
        returns (uint256)
    {
        return _userTotalWithdrawl[userAddress];
    }
}
