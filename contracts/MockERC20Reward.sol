// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//@dev MockERC20 for testing
contract MockERC20Reward is ERC20 {
    constructor(uint256 initialSupply) ERC20("Diamond", "DIA") {
        _mint(msg.sender, initialSupply);
    }

    receive() external payable{}
}