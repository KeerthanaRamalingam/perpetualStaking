// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPerpetualStaking {
    function maturityDate() external view returns (uint);
    function cliff() external view returns (uint);
    function getRewardOfToken(address tokenAddress) external view returns (uint);
}