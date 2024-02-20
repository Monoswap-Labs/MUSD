// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IERC20Rebasing.sol";

contract TestERC20Rebasing is ERC20, Ownable, IERC20Rebasing {
    constructor() ERC20("Test ERC20", "Test") Ownable(msg.sender) {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }

    function configure(YieldMode) external returns (uint256) {
        return 0;
    }

    // "claimable" yield mode accounts can call this this claim their yield
    // to another address
    function claim(
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        return 0;
    }
    // read the claimable amount for an account
    function getClaimableAmount(
        address account
    ) external view returns (uint256) {
        return 0;
    }
}
