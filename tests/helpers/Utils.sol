// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Utils is Test {
    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address public poolDelegateUSDC = 0x8c8C2431658608F5649B8432764a930c952d8A98;
    address public NSTBL_HUB = 0x749f88e87EaEb030E478164cFd3681E27d0bcB42;
    address public MAPLE_USDC_CASH_POOL = 0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92;
    address public MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;
    address public WITHDRAWAL_MANAGER_USDC = 0x1146691782c089bCF0B19aCb8620943a35eebD12;

    // EOA addresses
    address owner = address(123);
    address user = address(456);
    address admin = address(789);
    address user1 = vm.addr(101);

    /*//////////////////////////////////////////////////////////////
                               HELPERS
    //////////////////////////////////////////////////////////////*/

    function erc20_approve(address asset_, address account_, address spender_, uint256 amount_) internal {
        vm.startPrank(account_);
        IERC20(asset_).approve(spender_, amount_);
        vm.stopPrank();
    }

    function erc20_transfer(address asset_, address account_, address destination_, uint256 amount_) internal {
        vm.startPrank(account_);
        IERC20(asset_).transfer(destination_, amount_);
        vm.stopPrank();
    }

    function erc20_deal(address account_, uint256 amount_) internal {
        deal(USDC, account_, amount_, true);
    }
}
