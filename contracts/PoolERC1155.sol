// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPerpetualStaking.sol";
import "hardhat/console.sol";

contract PoolERC1155 is Ownable, ReentrancyGuard, ERC721Holder {

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

    //Deposit token used to create this contract
    address private _depositToken;

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
    event Withdraw(address tokenAddress, uint amount);

    // Event to record reinitilaized maturityDate
    event MaturityDate(uint updatedMaturityDate);

    // Event to record reinitilized platform fee
    event PlatformFee(uint platformFee);

    // Event to record updated reward amount of each token
    event RewardForTokens(uint reward, address tokenAddress);

    //Claim state catch
    event Claim(address tokenAddress, uint amount);

    constructor (address depositToken_, uint startDate_, uint maturityDate_, uint cliff_, address owner_) {
        _depositToken = depositToken_;

        // Cannot be initialized again. 
        // State of this variable remain same across functions
        _startDate = startDate_;
        _maturityDate = maturityDate_;
        _cliff = cliff_;
        transferOwnership(owner_);
    }

    modifier isExpired() {
        require(block.timestamp > _startDate);
        require(block.timestamp < maturityDate()); 
        _;
    }

    function deposit(uint nftID, uint batchID) external nonReentrant isExpired {
        require(IERC721(_depositToken).ownerOf(nftID) == msg.sender, "You are not the Owner");
        userPoolCount[msg.sender] ++;
        userDeposits[msg.sender][userPoolCount[msg.sender]] = Deposit (
            nftID,
            block.timestamp
        );
        IERC721(_depositToken).safeTransferFrom(msg.sender, address(this), nftID, "");
    }

    //Function to claim Rewards
    // Reward Can be claimed only after cliff
    function claim(address tokenAddress, uint amount) external {
        uint unclaimed;
        for(uint i = 1; i <= userPoolCount[msg.sender]; i++) {
            if(block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff) {
                unclaimed = getReward(tokenAddress, msg.sender, i);
            } 
            console.log("Unclaimed is %o", unclaimed);
        }
        require(unclaimed >= amount, "Trying to claim more than alloted");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Insufficient reward balance in contract");
        IERC20(tokenAddress).transfer(msg.sender, amount);
        _claimed[tokenAddress] = amount; 
        emit Claim(tokenAddress, amount);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, maturityDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(address tokenAddress, address user, uint depositID) public view returns (uint lastReward) {
        uint rewardCount = getRewardPerUnitOfDeposit(tokenAddress) * 10 ** IERC20Metadata(tokenAddress).decimals();// * userDeposits[user][depositID].depositBalance;
        lastReward = lastReward +
                    (((lastTimeRewardApplicable() - userDeposits[user][depositID].depositTime) * rewardCount) - _claimed[tokenAddress]);
    }

    // Withdraw deposit amount without reward
    // Withdraw happens only after cliff
    // Reward should be claimed seperately After cliff
    function withdraw(uint nftID) external {
        for(uint i = 1; i <= userPoolCount[msg.sender]; i++) {
            if(block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff) {
                if(userDeposits[msg.sender][i].depositBalance == nftID) {
                    IERC721(_depositToken).safeTransferFrom(address(this), msg.sender, nftID, "");
                    delete userDeposits[msg.sender][i];
                    emit Withdraw(_depositToken, nftID);
                }
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

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function updateTreasuryContract(address _treasuryContract) external onlyOwner {
        require(isContract(_treasuryContract), "Address is not a contract");
        _treasury = _treasuryContract;

    }

    function treasuryContract() public view returns(address) {
        return _treasury;
    }

    function depositToken() public view returns(address) {
        return _depositToken;
    }

    function claimed(address tokenAddress) public view returns(uint) {
        return _claimed[tokenAddress];
    }

    function userDeposit(address userAddress, uint poolCount) public view returns(Deposit memory depositdetails) {
        return userDeposits[userAddress][poolCount];
    }

    function userDepositCount(address userAddress) public view returns(uint) {
        return userPoolCount[userAddress];
    }
}