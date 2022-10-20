// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPerpetualStaking.sol";

contract PoolERC721 is Ownable, ReentrancyGuard, ERC721Holder {

    //Pool Maturity date: This is the date on which contract will stop accepting fresh deposits and will also stop accruing the rewards.
    // Can be reinitialised
    uint private _maturityDate;

    //Pool Start date: the date from which contract will start to accept the assets 
    uint private immutable _startDate;

    //Cliff: This is the lock-in period until which deposit assets cannot be withdrawn.
    uint private immutable _cliff;

    //PlatformFee: For ERC20, For each deposit, the platform may deduct fees.
    uint private _platformFee;

    // Treasury to maintain platform fee
    address private _treasury;

    //Maintain reward for each tokens
    mapping(address => uint) private rewardPerBlock;

    address private _rewardsDistribution;

    //Address of behold of this contract
    address private _beneficiery;

    //Deposit token used to create this contract
    address private _depositToken;

    //Token Batch
    uint private _batchID;

    //Maintain user balances
    uint private _depositBalance;

    //Claimed rewards
    mapping(address => uint) private _claimed;

    struct Deposit {
        uint depositBalance;
        uint depositTime;
    }
    //Maintain multiple deposits of users
    mapping(address => mapping(uint => Deposit)) private userDeposits;

    //Maintain user pool count
    mapping(address => uint) private userPoolCount;

    //Withdraw state catch
    event Withdraw(address tokenAddress, uint amount, uint batchID);

    // Event to record reinitilaized maturityDate
    event MaturityDate(uint updatedMaturityDate);

    // Event to record reinitilized platform fee
    event PlatformFee(uint platformFee);

    // Event to record updated reward amount of each token
    event RewardForTokens(uint reward, address tokenAddress);

    //Claim state catch
    event Claim(address tokenAddress, uint amount);

    constructor (address rewardsDistribution_, address beneficiery_, address depositToken_, uint startDate_, uint maturityDate_, uint cliff_) {
        _rewardsDistribution = rewardsDistribution_;
        _beneficiery = beneficiery_;
        _depositToken = depositToken_;

        // Cannot be initialized again. 
        // State of this variable remain same across functions
        _startDate = startDate_;
        _maturityDate = maturityDate_;
        _cliff = cliff_;
    }

    function deposit(uint nftID) external {
        require(IERC721(_depositToken).ownerOf(nftID) == msg.sender, "You are not the Owner");
        userPoolCount[msg.sender] ++;
        userDeposits[msg.sender][userPoolCount[msg.sender]] = Deposit (
            nftID,
            block.timestamp
        );
        IERC721(_depositToken).safeTransferFrom(msg.sender, address(this), nftID, "");
    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == _rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    //Function to claim Rewards
    // Reward Can be claimed only after cliff
    function claim(address tokenAddress, uint amount) external {
        uint unclaimed;
        for(uint i = 0; i < userPoolCount[msg.sender]; i++) {
            if(userDeposits[msg.sender][i].depositTime >= block.timestamp + _cliff) {
                unclaimed = getReward(tokenAddress, msg.sender, userDeposits[msg.sender][i].depositTime);
            } 
        }
        require(IERC20(tokenAddress).balanceOf(address(this)) >= unclaimed);
        IERC20(tokenAddress).transfer(_beneficiery, unclaimed);
        _claimed[tokenAddress] = unclaimed; 
        emit Claim(tokenAddress, amount);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, IPerpetualStaking(_rewardsDistribution).maturityDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(address tokenAddress, address user, uint depositID) public view returns (uint lastReward) {
        uint rewardCount = getRewardPerUnitOfDeposit(tokenAddress) * _depositBalance;
        lastReward = lastReward +
                    (((lastTimeRewardApplicable() - userDeposits[user][depositID].depositTime) * rewardCount) - _claimed[tokenAddress]);
    }

    // Withdraw deposit amount without reward
    // Withdraw happens only after cliff
    // Reward should be claimed seperately After cliff
    function withdraw(uint nftID) external {
        for(uint i = 0; i < userPoolCount[msg.sender]; i++) {
            if(userDeposits[msg.sender][i].depositTime >= block.timestamp + _cliff) {
                if(userDeposits[msg.sender][i].depositBalance == nftID)
                    IERC721(_depositToken).safeTransferFrom(address(this), msg.sender, nftID, "");
                    delete userDeposits[msg.sender][i];
            } 
        }
    }

    function getRewardPerUnitOfDeposit(address tokenAddress) public view returns (uint) {
        return rewardPerBlock[tokenAddress];
    }

    // return start date of the pool    
    function startDate() public view returns (uint) {
        return _startDate;
    }

    // return maturity date of the pool
    function maturityDate() public view returns (uint) {
        return _maturityDate;
    }

    // return cliff of the pool
    function cliff() public view returns (uint) {
        return _cliff;
    }

    // Reassigning maturity Date 
    // checks Ownership and internal call
    function updateMaturityDate(uint newMaturityDate) external onlyOwner {
        _updateMaturityDate(newMaturityDate);
    }

    // safe Internal call to update MaturityDate
    function _updateMaturityDate(uint maturitydate_) internal {
        _maturityDate = maturitydate_;
        emit MaturityDate(_maturityDate);
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
    function updateRewardForToken(uint newReward, address tokenAddress) external onlyOwner {
        rewardPerBlock[tokenAddress] = newReward;
        emit RewardForTokens(newReward, tokenAddress);
    } 

}