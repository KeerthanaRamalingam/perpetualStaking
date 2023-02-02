// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPerpetualStaking.sol";
import "hardhat/console.sol";

contract PoolERC1155 is Ownable, ReentrancyGuard, ERC1155Holder {

    //Pool Maturity date: This is the date on which contract will stop accepting fresh deposits and will also stop accruing the rewards.
    // Can be reinitialised
    uint private _endDate;

    //Pool Start date: the date from which contract will start to accept the assets 
    uint private immutable _startDate;

    //Cliff: This is the lock-in period until which deposit assets cannot be withdrawn.
    uint private immutable _cliff;

    //PlatformFee: For ERC20, For each deposit, the platform may deduct fees.
    uint private _platformFee;

    // Treasury to maintain platform fee
    address private _treasury;

    //Maintain reward for each tokens
    address[] private rewardTokens;

    //Maintain reward for each tokens
    mapping(address => uint) private rewardForDeposit;

    //Deposit token used to create this contract
    address private _depositToken;

    //total deposit
    uint256 private _totalDeposit;

    //Claimed rewards
    mapping(address => uint) private _claimed;

    mapping(address => mapping(address => uint256)) private _userClaimed;

    mapping(address => uint256) private _userTotalWithdrawl;

    struct Deposit {
        uint depositBalance;
        uint batchID;
        uint depositTime;
        uint256 claimedReward;
        uint256 claimedTime;
    }
    //Maintain multiple deposits of users
    mapping(address => mapping(uint => Deposit)) private userDeposits;

    //Maintain user pool count
    mapping(address => uint) private userPoolCount;

    //Withdraw state catch
    event Withdraw(address tokenAddress, uint amount);

    // Event to record reinitilaized maturityDate
    event EndDate(uint updatedEndDate);

    // Event to record reinitilized platform fee
    event PlatformFee(uint platformFee);

    // Event to record updated reward amount of each token
    event RewardForTokens(uint256[] reward, address[] tokenAddress);

    //Claim state catch
    event Claim(address tokenAddress, uint amount);

    constructor (address depositToken_, uint startDate_, uint endDate_, uint cliff_, address owner_, address[] memory rewardTokens_,
        uint256[] memory rewardUnits_) {
        _depositToken = depositToken_;

        // Cannot be initialized again. 
        // State of this variable remain same across functions
        _startDate = startDate_;
        _endDate = endDate_;
        _cliff = cliff_;
        updateRewardForToken(rewardUnits_, rewardTokens_);
        transferOwnership(owner_);
    }

    modifier isExpired() {
        require(block.timestamp > _startDate);
        require(block.timestamp < endDate()); 
        _;
    }

    function deposit(uint batchID, uint amount) external nonReentrant isExpired {
        require(IERC1155(_depositToken).balanceOf(msg.sender, batchID) >= amount, "Insufficient balance");
        userPoolCount[msg.sender]++;
        _totalDeposit += amount;
        userDeposits[msg.sender][userPoolCount[msg.sender]] = Deposit (
            amount,
            batchID,
            block.timestamp,
            0,
            block.timestamp
        );
        IERC1155(_depositToken).safeTransferFrom(msg.sender, address(this), batchID, amount, "");
    }

    //Function to claim Rewards
    // Reward Can be claimed only after cliff
    function claimTokenReward(address tokenAddress) external {
        uint256 unclaimed;
        uint256 reward;
        for(uint256 i = 1; i <= userPoolCount[msg.sender]; i++ ) {
            if(_cliff < 0 || block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff) {
                reward = getReward(tokenAddress, msg.sender, i);
                if(reward != 0) {
                    unclaimed += reward;
                    userDeposits[msg.sender][i].claimedReward += reward;
                    userDeposits[msg.sender][i].claimedTime = block.timestamp;
                }
            }
        }
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= unclaimed,
            "Insufficient reward balance in contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, unclaimed);
        _claimed[tokenAddress] += unclaimed;
        _userClaimed[msg.sender][tokenAddress] += unclaimed;
        emit Claim(tokenAddress, unclaimed);
        
    }

    function claimAllReward() public {
        uint256 unclaimed = 0;
        uint256 rewardAmount = 0;   
        for (uint256 j = 0; j < rewardTokens.length; j++) {
            for(uint256 i = 1; i <= userPoolCount[msg.sender]; i++ ) {
                if(_cliff < 0 || block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff) {
                    rewardAmount = getReward(rewardTokens[j], msg.sender, i);
                    if(rewardAmount != 0) {
                        unclaimed += rewardAmount;   
                        userDeposits[msg.sender][i].claimedReward += rewardAmount;
                        userDeposits[msg.sender][i].claimedTime = block.timestamp;
                    }
                }
            }
            require(
                IERC20(rewardTokens[j]).balanceOf(address(this)) >= unclaimed,
                "Insufficient reward balance in contract"
            ); 
            IERC20(rewardTokens[j]).transfer(msg.sender, unclaimed);
            _claimed[rewardTokens[j]] += unclaimed;
            _userClaimed[msg.sender][rewardTokens[j]] += unclaimed;
            emit Claim(rewardTokens[j], unclaimed);
        }
          
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, endDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(address tokenAddress, address user, uint depositID) public view returns (uint lastReward) {
        uint rewardCount = getRewardPerUnitOfDeposit(tokenAddress) * 
        userDeposits[user][depositID].depositBalance;
        if(userDeposits[user][depositID].claimedTime != 0 && userDeposits[user][depositID].claimedTime <= endDate()) {
            lastReward = lastReward +
            ((lastTimeRewardApplicable() - userDeposits[user][depositID].claimedTime) * rewardCount); 
        }
        else {
            return 0;
        }
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
                userDeposits[userAddress][i].depositTime + _cliff
            ) {
                rewardAmount += getReward(rewardTokenAddress, userAddress, i);
            }
        }
    }

    // Withdraw deposit amount without reward
    // Withdraw happens only after cliff
    // Reward should be claimed seperately After cliff
    function withdraw(uint batchID, uint amount) external nonReentrant{
        claimAllReward();
        for(uint i = 1; i <= userPoolCount[msg.sender]; i++) {
            if(block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff) {
                if(batchID == userDeposits[msg.sender][i].batchID) {
                    if(userDeposits[msg.sender][i].depositBalance > amount) {
                        userDeposits[msg.sender][i].depositBalance -= amount;
                        _totalDeposit -= amount;
                        _userTotalWithdrawl[msg.sender] += amount;
                        IERC1155(_depositToken).safeTransferFrom(address(this), msg.sender, batchID, amount, "");
                        emit Withdraw(_depositToken, amount);
                        break;
                    }
                    else {
                        amount = amount - userDeposits[msg.sender][i].depositBalance;
                        _totalDeposit -= userDeposits[msg.sender][i].depositBalance;
                        _userTotalWithdrawl[msg.sender] += userDeposits[msg.sender][i].depositBalance;
                        IERC1155(_depositToken).safeTransferFrom(address(this), msg.sender, batchID, userDeposits[msg.sender][i].depositBalance, "");
                        delete userDeposits[msg.sender][i];
                        emit Withdraw(_depositToken, userDeposits[msg.sender][i].depositBalance);
                    }
                }
            } 
        }
    }

    function getRewardPerUnitOfDeposit(address tokenAddress) public view returns (uint) {
        return rewardForDeposit[tokenAddress];
    }

    // return start date of the pool    
    function startDate() public view returns (uint) {
        return _startDate;
    }

    // return maturity date of the pool
    function endDate() public view returns (uint) {
        return _endDate;
    }

    // return cliff of the pool
    function cliff() public view returns (uint) {
        return _cliff;
    }

    // Reassigning maturity Date 
    // checks Ownership and internal call
    function updateEndDate(uint _endDate_) external onlyOwner {
        _updateEndDate(_endDate_);
    }

    // safe Internal call to update MaturityDate
    function _updateEndDate(uint endDate_) internal {
        _endDate = endDate_;
        emit EndDate(endDate_);
    }

    // Reassigning platform Fee
    // checks Ownership and internal call
    function updatePlatformFee(uint newPlatformFee) external onlyOwner {
        _updatePlatformFee(newPlatformFee);
    }

    // safe Internal call to update MaturityDate
    function _updatePlatformFee(uint platformFee_) internal {
        _platformFee = platformFee_;
        emit PlatformFee(_platformFee);
    }

    // Reassigning reward for tokens
    function updateRewardForToken( uint256[] memory newReward, address[] memory tokenAddress) internal onlyOwner {
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

    function updateTreasury(address _treasuryContract) external onlyOwner {
        require(isContract(_treasuryContract), "Address is not a contract");
        _treasury = _treasuryContract;

    }

    function platformFee() public view returns (uint256) {
        return _platformFee;
    }

    function treasury() public view returns(address) {
        return _treasury;
    }

    function depositToken() public view returns(address) {
        return _depositToken;
    }

    function totalClaimed(address tokenAddress) public view returns(uint) {
        return _claimed[tokenAddress];
    }

    function depositDetailsByID(address userAddress, uint256 depositID)
        public
        view
        returns (Deposit memory depositdetails)
    {
        return userDeposits[userAddress][depositID];
    }

    function userDepositCount(address userAddress) public view returns(uint) {
        return userPoolCount[userAddress];
    }

    function userDeposit(address userAddress) public view returns(uint256 balance) {
        for (uint256 i = 1; i<= userPoolCount[userAddress]; i++) {
            balance += userDeposits[userAddress][i].depositBalance;
        }
    }

    function rewardToken(uint256 rewardTokenIndex)
        public
        view
        returns(address) 
    {
        return rewardTokens[rewardTokenIndex];

    }

    function rewardTokenCount() public view returns (uint256) {
        return rewardTokens.length;
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