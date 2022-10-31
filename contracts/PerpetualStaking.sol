// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./PoolERC20.sol";
import "./PoolERC721.sol";

// Reward will always be in ERC20
// Deposit can be in ERC20,ERC721,ERC1155
// Declaring variable to private to have same state in inherited contracts
contract PerpetualStaking is Ownable, ReentrancyGuard {
    using ERC165Checker for address;

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

    function deployNewPool(
        address depositToken_,
        uint256 startDate_,
        uint256 maturityDate_,
        uint256 cliff_
    ) external nonReentrant onlyOwner returns (address){
        address newPool;
        if (isERC721(depositToken_)) {
            newPool = address(
                new PoolERC721(depositToken_, startDate_, maturityDate_, cliff_, msg.sender)
            );
        } else if (isERC1155(depositToken_)) {
            newPool = address(0);
            ///---------------- Pending---------------------//
        } else {
            // we assume if token address is ERC20 if it is not ERC721 or ERC1155
            newPool = address(
                new PoolERC20(depositToken_, startDate_, maturityDate_, cliff_, msg.sender)
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
