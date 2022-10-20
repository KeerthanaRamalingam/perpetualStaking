// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPool {
    function deposit(address tokenAddress, uint amountOrID, uint batchID) external;
}