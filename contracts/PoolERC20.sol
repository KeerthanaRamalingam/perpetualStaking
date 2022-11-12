// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPerpetualStaking.sol";
// import "hardhat/console.sol";

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
        rewardTokens = tokenAddress;
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
        require(block.timestamp < maturityDate());
        _;
    }

    function deposit(uint256 amount) external nonReentrant isExpired {
        require(
            IERC20(_depositToken).balanceOf(msg.sender) >= amount,
            "You are not the Owner"
        );
        userPoolCount[msg.sender]++;
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
        // console.log("Unclaimed is %o", unclaimed);
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

    function claim() external {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                for (uint256 j = 0; j < rewardTokens.length; j++) {
                    unclaimed = getReward(rewardTokens[j], msg.sender, j);
                    require(
                        IERC20(rewardTokens[j]).balanceOf(address(this)) >=
                            unclaimed,
                        "Insufficient reward balance in contract"
                    );
                    IERC20(rewardTokens[j]).transfer(msg.sender, unclaimed);
                    _claimed[rewardTokens[j]] = unclaimed;
                    emit Claim(rewardTokens[j], unclaimed);
                }
            }
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, maturityDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(
        address tokenAddress,
        address user,
        uint256 depositID
    ) public view returns (uint256 lastReward) {
        uint256 rewardCount = getRewardPerUnitOfDeposit(tokenAddress) *
            userDeposits[user][depositID].depositBalance;
        lastReward =
            lastReward +
            (((lastTimeRewardApplicable() -
                userDeposits[user][depositID].depositTime) * rewardCount) -
                _claimed[tokenAddress]);
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
                cliff() < 0 || block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                // console.log("Inside loop is %o", block.timestamp);
                // Commented for unit testing (implement block increase)
                // if first pool has greater amount than required, subract and do nothing
                if (
                    userDeposits[msg.sender][i].depositBalance > 0 &&
                    userDeposits[msg.sender][i].depositBalance > pendingAmount
                ) {
                    IERC20(_depositToken).transfer(msg.sender, pendingAmount);
                    userDeposits[msg.sender][i].depositBalance -= pendingAmount;
                }
                // if first pool has lesser amount, subract the amount and save the remaining amount and delete the first pool
                else {
                    pendingAmount =
                        pendingAmount -
                        userDeposits[msg.sender][i].depositBalance;
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

    // ------------ CHECK IF CLIFF IS > 0 GLOBAL IN WITHDRAW AND CLAIM  --done
    // deposit - 3 times
    // 1st - 100
    // 15th - 100 //--------------  TERMINATE THE POOL HERE
    // 29th - 100
    // 31 - ATW - 100  - done

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

    function userDeposit(address userAddress, uint256 poolCount)
        public
        view
        returns (Deposit memory depositdetails)
    {
        return userDeposits[userAddress][poolCount];
    }

    function userDepositCount(address userAddress)
        public
        view
        returns (uint256)
    {
        return userPoolCount[userAddress];
    }
}
