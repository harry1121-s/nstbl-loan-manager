// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../helpers/BaseTest.t.sol";

contract TestDeposit is BaseTest {
    using SafeERC20 for IERC20;

    function setUp() public virtual override {
        super.setUp();
    }

    function testInvestUSDC() public {
        _investAssets(USDC, address(usdcPool));
    }

    function testInvestUSDT() public {
        _investAssets(USDT, address(usdtPool));
    }
}

contract TestRequestRedeem is BaseTest {
    using SafeERC20 for IERC20;

    function setUp() public override {
        super.setUp();
    }

    function testRedeemRequestUSDC() external {
        _investAssets(USDC, address(usdcPool));

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        lusdc.approve(address(loanManager), lmUSDC);
        loanManager.requestRedeem(address(usdc), lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), 0);
        assertEq(lusdc.balanceOf(address(loanManager)), lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), lmUSDC / 10 ** 12);
        vm.stopPrank();
    }

    function testRedeemRequestUSDC_PendingRedemption() external {
        _investAssets(USDC, address(usdcPool));

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        lusdc.approve(address(loanManager), lmUSDC / 2);
        loanManager.requestRedeem(address(usdc), lmUSDC / 2);
        // assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC / 2);
        // assertEq(lusdc.balanceOf(address(loanManager)), lmUSDC / 2);
        // assertEq(usdcPool.balanceOf(address(loanManager)), lmUSDC / (2 * 10 ** 12));
        // assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), lmUSDC / (2 * 10 ** 12));

        vm.expectRevert("LM: Redemption Pending");
        loanManager.requestRedeem(address(usdc), lmUSDC / 2);

        vm.stopPrank();
    }

    function testRedeemRequestUSDT() external {
        _investAssets(USDT, address(usdtPool));

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        lusdt.safeIncreaseAllowance(address(loanManager), lmUSDT);
        loanManager.requestRedeem(address(usdt), lmUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), 0);
        assertEq(lusdt.balanceOf(address(loanManager)), lmUSDT);
        assertEq(usdtPool.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), lmUSDT / 10 ** 12);
        vm.stopPrank();
    }

    function testRedeemRequestUSDT_PendingRedemption() external {
        _investAssets(USDT, address(usdtPool));

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        lusdt.safeIncreaseAllowance(address(loanManager), lmUSDT / 2);
        loanManager.requestRedeem(address(usdt), lmUSDT / 2);
        // assertEq(lusdt.balanceOf(NSTBL_HUB), lmUSDT / 2);
        // assertEq(lusdt.balanceOf(address(loanManager)), lmUSDT / 2);
        // assertEq(usdtPool.balanceOf(address(loanManager)), lmUSDT / (2 * 10 ** 12));
        // assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), lmUSDT / (2 * 10 ** 12));

        vm.expectRevert("LM: Redemption Pending");
        loanManager.requestRedeem(address(usdt), lmUSDT / 2);

        vm.stopPrank();
    }
}

contract TestRedeem is BaseTest {
    using SafeERC20 for IERC20;

    function testRedeemUSDC() external {
        _investAssets(USDC, address(usdcPool));

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        lusdc.approve(address(loanManager), lmUSDC);
        loanManager.requestRedeem(address(usdc), lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), 0);
        assertEq(lusdc.balanceOf(address(loanManager)), lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), lmUSDC / 10 ** 12);

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loanManager.redeem(address(usdc));

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(address(usdc), lmUSDC);
        loanManager.redeem(address(usdc));
        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        assertEq(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(lusdc.totalSupply(), 0);
        assertFalse(loanManager.awaitingRedemption(address(usdc)));
        vm.stopPrank();
    }

    function testRedeemUSDT() external {
        _investAssets(USDT, address(usdtPool));

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        lusdt.safeIncreaseAllowance(address(loanManager), lmUSDT);
        loanManager.requestRedeem(address(usdt), lmUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), 0);
        assertEq(lusdt.balanceOf(address(loanManager)), lmUSDT);
        assertEq(usdtPool.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), lmUSDT / 10 ** 12);

        uint256 _currCycleId = withdrawalManagerUSDT.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDT.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDT.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loanManager.redeem(address(usdt));

        uint256 usdtBal1 = usdt.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDT = loanManager.getAssetsWithUnrealisedLosses(address(usdt), lmUSDT);
        loanManager.redeem(address(usdt));
        uint256 usdtBal2 = usdt.balanceOf(NSTBL_HUB);
        // assertEq(usdtBal2 - usdtBal1, expectedUSDT);
        assertEq(lusdt.balanceOf(address(loanManager)), 0);
        assertEq(lusdt.totalSupply(), 0);
        assertFalse(loanManager.awaitingRedemption(address(usdt)));
        vm.stopPrank();
    }
}
