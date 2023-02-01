// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBuddy {
    function isTokenIdMapped(uint256 tokenId, address collection) external view returns(uint256[] memory);
}