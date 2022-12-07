// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "./PoolERC20.sol";
import "./PoolERC721.sol";

// Reward will always be in ERC20
// Deposit can be in ERC20,ERC721,ERC1155
// Declaring variable to private to have same state in inherited contracts
// @title Perpetual Staking contract act as factory to deploy new ERC20, ERC721, ERC1155 Pools.
contract PerpetualStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ERC165CheckerUpgradeable for address;

    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    event NewPoolCreated(
        address depositToken,
        uint256 startDate,
        uint256 maturityDate,
        uint256 cliff,
        address poolAddress
    );

    address[] private pools;

    function initialize() public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
    }

    ///@notice Owner function to deploy new pools - ERC20,ERC721,ERC1155
    ///@param depositToken_ Token for which pool is to be created
    ///@param startDate_ Start time of the pool
    ///@param maturityDate_ Maturity time of the pool
    ///@param cliff_ Cliff of the pool
    ///@param rewardTokens_ Reward token addresses of the pool. Expected to be ERC20 tokens
    ///@param rewardUnits_ Reward Units to be given per deposit
    ///@return Deployed pool address
    function deployNewPool(
        address depositToken_,
        uint256 startDate_,
        uint256 maturityDate_,
        uint256 cliff_,
        address[] memory rewardTokens_,
        uint[] memory rewardUnits_
    ) external nonReentrant onlyOwner returns (address){
        address newPool;
        if (isERC721(depositToken_)) {
            newPool = address(
                new PoolERC721(depositToken_, startDate_, maturityDate_, cliff_, msg.sender, rewardTokens_, rewardUnits_)
            );
        } else if (isERC1155(depositToken_)) {
            newPool = address(0);
            ///---------------- Pending---------------------//
        } else {
            // we assume if token address is ERC20 if it is not ERC721 or ERC1155
            newPool = address(
                new PoolERC20(depositToken_, startDate_, maturityDate_, cliff_, msg.sender, rewardTokens_, rewardUnits_)
            );
        }
        pools.push(newPool);
        emit NewPoolCreated(
            depositToken_,
            startDate_,
            maturityDate_,
            cliff_,
            newPool
        );
        return newPool;
    }

    // Check whether contract address is ERC1155
    function isERC1155(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }

    // Check whether contract address is ERC721
    function isERC721(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }

    function poolsDeployed() public view returns (address[] memory) {
        return pools;
    }
}
