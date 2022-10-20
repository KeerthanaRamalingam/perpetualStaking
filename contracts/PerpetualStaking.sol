// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./Pool.sol";
import "./IPool.sol";

// Reward will always be in ERC20
// Deposit can be in ERC20,ERC721,ERC1155
// Declaring variable to private to have same state in inherited contracts
contract PerpetualStaking is Ownable, ReentrancyGuard  {
    using ERC165Checker for address;

    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

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

    //Maintain user balances
    mapping(address => mapping(address => uint)) public userBalances;

    //Maintain user rewards
    mapping(address => mapping(address => uint)) public userReward;

    //Maintain user's claimed rewards
    mapping(address => mapping(address => uint)) public userRewardClaimed;

    //Maintain reward for each tokens
    mapping(address => uint) private rewardPerBlock;

    mapping(address => address[]) public userPools;

    //Maintain last deposit time
    mapping(address => uint) public lastDepositTime;

    // Event to record reinitilaized maturityDate
    event MaturityDate(uint updatedMaturityDate);

    // Event to record reinitilized platform fee
    event PlatformFee(uint platformFee);

    // Event to record updated reward amount of each token
    event RewardForTokens(uint reward, address tokenAddress);

    // Event to record Deposit
    event Deposit(uint amount, uint batchID, address tokenAddress, address newPool);

    constructor(uint startDate_, uint maturityDate_, uint cliff_) {
        // Cannot be initialized again. 
        // State of this variable remain same across functions
        _startDate = startDate_;
        _maturityDate = maturityDate_;
        _cliff = cliff_;
    }

    modifier isExpired() {
        require(block.timestamp > _startDate); _;
    }

    // User Deposit - ERC20/ERC721/ERC1155 
    // batchID - Incase of ERC1155 -------------- SHOULD BE TESTED ----------------------------
    function deposit(address tokenAddress, uint amountOrID, uint batchID) external nonReentrant isExpired {
        require(block.timestamp < maturityDate());
        address newPool = address(new Pool(address(this), msg.sender, tokenAddress, amountOrID, batchID));
        if(isERC721(tokenAddress))  { 
            IERC721(tokenAddress).safeTransferFrom(msg.sender, newPool, amountOrID, "");
        } 
        else if(isERC1155(tokenAddress)) IERC1155(tokenAddress).safeTransferFrom(msg.sender, newPool, batchID , amountOrID, "");
        // we assume if token address is ERC20 if it is not ERC721 or ERC1155
        else {
            uint fee = amountOrID - (amountOrID * _platformFee / 10000);
            IERC20(tokenAddress).transferFrom(msg.sender, newPool, amountOrID);
            IERC20(tokenAddress).transfer(_treasury, fee);
        }
        userPools[msg.sender].push(newPool);
        emit Deposit(amountOrID, batchID, tokenAddress, newPool);
    }

    // Check whether contract address is ERC1155
    function isERC1155(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }    
    
    // Check whether contract address is ERC721
    function isERC721(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }

    function getRewardOfToken(address tokenAddress) public view returns (uint) {
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
