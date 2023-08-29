// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Utils is Test {
    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address public poolDelegateUSDC = 0x8c8C2431658608F5649B8432764a930c952d8A98;
    address public poolDelegateUSDT = 0xCc780Fe0e08Ff81B1c1315d7F63E4ec04F21fe86;
    address public NSTBL_HUB = 0x749f88e87EaEb030E478164cFd3681E27d0bcB42;
    address public MAPLE_USDC_CASH_POOL = 0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92;
    address public MAPLE_USDT_CASH_POOL = 0xf05681A33a9ADF14076990789A89ab3dA3F6B536;

    // EOA addresses
    address owner = address(123);
    address user = address(456);
    address admin = address(789);

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

    function erc20_deal(address asset_, address account_, uint256 amount_) internal {
        if (asset_ == USDT) deal(USDT, account_, amount_, true);
        else if (asset_ == USDC) deal(USDC, account_, amount_, true);
    }
}
