// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../helpers/BaseTest.t.sol";

contract TestDeposit is BaseTest {
    using SafeERC20 for IERC20;

    function setUp() public virtual override {
        super.setUp();
    }

    function test_deposit_pass_USDC() public {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        uint256 sharesToReceive = usdcPool.previewDeposit(amount);
        assertEq(IERC20(USDC).balanceOf(user), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), sharesToReceive);
    }

    function test_deposit_pass_USDT() public {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDT, address(usdtPool), amount);

        uint256 sharesToReceive = usdtPool.previewDeposit(amount);
        assertEq(IERC20(USDT).balanceOf(user), 0);
        assertEq(usdtPool.balanceOf(address(loanManager)), sharesToReceive);
    }

    function test_deposit_pass_USDC_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        // Action
        _investAssets(USDC, address(usdcPool), amount);

        // Assert
        uint256 sharesToReceive = usdcPool.previewDeposit(amount);
        assertEq(IERC20(USDC).balanceOf(user), 0, "balance of user changes to 0");
        assertEq(
            usdcPool.balanceOf(address(loanManager)),
            sharesToReceive,
            "USDC Cash LP token balance of loanManager increases"
        );
    }

    function testFail_deposit_revert_invalid_amount_lowerBound_USDC_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares == 0);

        // Action
        _investAssets(USDC, address(usdcPool), amount);
    }

    function testFail_deposit_revert_invalid_amount_upperBound_USDC_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < type(uint256).max - 1);
        vm.assume(amount > _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));

        // Action
        // vm.expectRevert("LM: Invalid amount"); @TODO: fix this
        _investAssets(USDC, address(usdcPool), amount);
    }

    function testFail_deposit_revert_invalid_amount_lowerBound_USDT_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDT_CASH_POOL, address(poolManagerUSDT)));
        uint256 shares = usdtPool.previewDeposit(amount);
        vm.assume(shares == 0);

        // Action
        _investAssets(USDT, address(usdtPool), amount);
    }

    function testFail_deposit_revert_invalid_amount_upperBound_USDT_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < type(uint256).max - 1);
        vm.assume(amount > _getUpperBoundDeposit(MAPLE_USDT_CASH_POOL, address(poolManagerUSDT)));

        // Action
        // vm.expectRevert("LM: Invalid amount"); @TODO: fix this
        _investAssets(USDT, address(usdtPool), amount);
    }

    function test_deposit_USDT_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDT_CASH_POOL, address(poolManagerUSDT)));
        uint256 shares = usdtPool.previewDeposit(amount);
        vm.assume(shares > 0);

        // Action
        _investAssets(USDT, address(usdtPool), amount);

        // Assert
        uint256 sharesToReceive = usdtPool.previewDeposit(amount);
        assertEq(IERC20(USDT).balanceOf(user), 0);
        assertEq(usdtPool.balanceOf(address(loanManager)), sharesToReceive);
    }
}

contract TestRequestRedeem is BaseTest {
    using SafeERC20 for IERC20;

    function setUp() public override {
        super.setUp();
    }

    function test_requestRedeem_USDC() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), lmUSDC / 10 ** 12);
        vm.stopPrank();
    }

    function test_requestRedeem_and_deposit_USDC() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);

        loanManager.requestRedeem(address(usdc), lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), lmUSDC / 10 ** 12);
        assertTrue(loanManager.awaitingRedemption(USDC));
        vm.stopPrank();
        _investAssets(USDC, address(usdcPool), amount);
    }

    function test_requestRedeem_USDC_fullLP_pass_fuzz(uint256 amount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, address(usdcPool), amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), lmUSDC / 10 ** 12);
        vm.stopPrank();
    }

    function test_requestRedeem_USDC_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, address(usdcPool), amount);
        vm.assume(redeemAmount < IPool(MAPLE_USDC_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), redeemAmount);

        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12, "loanmanager");
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), redeemAmount / 10 ** 12, "withdrawal");
        vm.stopPrank();
    }

    function test_requestRedeem_USDC_revert_pendingRedemption() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), lmUSDC / 2);

        vm.expectRevert("LM: Redemption Pending");
        loanManager.requestRedeem(address(usdc), lmUSDC / 2);

        vm.stopPrank();
    }

    function test_requestRedeem_USDT() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDT, address(usdtPool), amount);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdt), lmUSDT);
        assertEq(usdtPool.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), lmUSDT / 10 ** 12);
        vm.stopPrank();
    }

    function test_requestRedeem_and_deposit_USDT() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDT, address(usdtPool), amount);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);

        loanManager.requestRedeem(address(usdt), lmUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), lmUSDT);
        assertEq(lusdt.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), lmUSDT / 10 ** 12);
        assertTrue(loanManager.awaitingRedemption(USDT));
        vm.stopPrank();
        _investAssets(USDT, address(usdtPool), amount);
    }

    function test_requestRedeem_USDT_fullLP_pass_fuzz(uint256 amount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDT_CASH_POOL, address(poolManagerUSDT)));
        uint256 shares = usdtPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDT, address(usdtPool), amount);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdt), lmUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), lmUSDT);
        assertEq(lusdt.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(loanManager)), 0);
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), lmUSDT / 10 ** 12);
        vm.stopPrank();
    }

    function test_requestRedeem_USDT_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDT_CASH_POOL, address(poolManagerUSDT)));
        uint256 shares = usdtPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDT, address(usdtPool), amount);
        vm.assume(redeemAmount < IPool(MAPLE_USDT_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdt), redeemAmount);

        assertEq(usdtPool.balanceOf(address(loanManager)), (lmUSDT - redeemAmount) / 1e12, "loanmanager");
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), redeemAmount / 10 ** 12, "withdrawal");
        vm.stopPrank();
    }

    function test_requestRedeem_USDT_revert_pendingRedemption() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDT, address(usdtPool), amount);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdt), lmUSDT / 2);

        vm.expectRevert("LM: Redemption Pending");
        loanManager.requestRedeem(address(usdt), lmUSDT / 2);

        vm.stopPrank();
    }
}

contract TestRedeem is BaseTest {
    using SafeERC20 for IERC20;

    function test_redeem_USDC() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        console.log("lUSDC minted - ", lmUSDC);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), lmUSDC);
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
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares(address(lusdc)) * 10 ** 12);
        assertEq(lusdc.totalSupply(), loanManager.escrowedMapleShares(address(lusdc)) * 10 ** 12);
        console.log("lUSDC pending redemption - ", loanManager.getLpTokensPendingRedemption(address(lusdc)));
        if (loanManager.escrowedMapleShares(address(lusdc)) == 0) {
            assertFalse(loanManager.awaitingRedemption(address(usdc)));
        } else {
            assertTrue(loanManager.awaitingRedemption(address(usdc)));
        }
        vm.stopPrank();
    }

    function test_redeem_USDT() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDT, address(usdtPool), amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);
        console.log("lUSDT minted - ", lmUSDT);
        vm.startPrank(NSTBL_HUB);
        lusdt.safeIncreaseAllowance(address(loanManager), lmUSDT);
        loanManager.requestRedeem(address(usdt), lmUSDT);
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
        console.log(usdtBal2 - usdtBal1, expectedUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares(address(lusdt)) * 10 ** 12);
        assertEq(lusdt.totalSupply(), loanManager.escrowedMapleShares(address(lusdt)) * 10 ** 12);
        console.log("lUSDT pending redemption - ", loanManager.getLpTokensPendingRedemption(address(lusdt)));
        if (loanManager.escrowedMapleShares(address(lusdt)) == 0) {
            assertFalse(loanManager.awaitingRedemption(address(usdt)));
        } else {
            assertTrue(loanManager.awaitingRedemption(address(usdt)));
        }
        vm.stopPrank();
    }

    function test_redeem_USDC_fullLP_pass_fuzz(uint256 amount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, address(usdcPool), amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
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
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares(address(lusdc)) * 10 ** 12);
        assertEq(lusdc.totalSupply(), loanManager.escrowedMapleShares(address(lusdc)) * 10 ** 12);
        if (loanManager.escrowedMapleShares(address(lusdc)) == 0) {
            assertFalse(loanManager.awaitingRedemption(address(usdc)));
        } else {
            assertTrue(loanManager.awaitingRedemption(address(usdc)));
        }
        vm.stopPrank();
    }

    function test_redeem_USDT_fullLP_pass_fuzz(uint256 amount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDT_CASH_POOL, address(poolManagerUSDT)));
        uint256 shares = usdtPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDT, address(usdtPool), amount);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdt), lmUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), lmUSDT);
        assertEq(lusdt.balanceOf(address(loanManager)), 0);
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
        console.log(usdtBal2 - usdtBal1, expectedUSDT);
        assertEq(lusdt.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares(address(lusdt)) * 10 ** 12);
        assertEq(lusdt.totalSupply(), loanManager.escrowedMapleShares(address(lusdt)) * 10 ** 12);
        if (loanManager.escrowedMapleShares(address(lusdt)) == 0) {
            assertFalse(loanManager.awaitingRedemption(address(usdt)));
        } else {
            assertTrue(loanManager.awaitingRedemption(address(usdt)));
        }
        vm.stopPrank();
    }

    function test_requestRedeem_USDC_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, address(usdcPool), amount);
        vm.assume(redeemAmount < IPool(MAPLE_USDC_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdc), redeemAmount);

        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12, "loanmanager");
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), redeemAmount / 10 ** 12, "withdrawal");

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loanManager.redeem(address(usdc));

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(address(usdc), redeemAmount);
        loanManager.redeem(address(usdc));
        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(
            lusdc.balanceOf(NSTBL_HUB),
            lmUSDC - redeemAmount - loanManager.escrowedMapleShares(address(lusdc)) * 10 ** 12
        );
        assertEq(
            lusdc.totalSupply(), lmUSDC - redeemAmount - loanManager.escrowedMapleShares(address(lusdc)) * 10 ** 12
        );
        if (loanManager.escrowedMapleShares(address(lusdc)) == 0) {
            assertFalse(loanManager.awaitingRedemption(address(usdc)));
        } else {
            assertTrue(loanManager.awaitingRedemption(address(usdc)));
        }
        vm.stopPrank();
    }

    function test_requestRedeem_USDT_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDT)));
        uint256 shares = usdtPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDT, address(usdtPool), amount);
        vm.assume(redeemAmount < IPool(MAPLE_USDT_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);

        uint256 lmUSDT = lusdt.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(address(usdt), redeemAmount);

        assertEq(usdtPool.balanceOf(address(loanManager)), (lmUSDT - redeemAmount) / 1e12, "loanmanager");
        assertEq(usdtPool.balanceOf(address(withdrawalManagerUSDT)), redeemAmount / 10 ** 12, "withdrawal");

        uint256 _currCycleId = withdrawalManagerUSDT.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDT.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDT.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loanManager.redeem(address(usdt));

        uint256 usdtBal1 = usdt.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDT = loanManager.getAssetsWithUnrealisedLosses(address(usdt), redeemAmount);
        loanManager.redeem(address(usdt));
        uint256 usdtBal2 = usdt.balanceOf(NSTBL_HUB);
        console.log(usdtBal2 - usdtBal1, expectedUSDT);
        assertEq(
            lusdt.balanceOf(NSTBL_HUB),
            lmUSDT - redeemAmount - loanManager.escrowedMapleShares(address(lusdt)) * 10 ** 12
        );
        assertEq(
            lusdt.totalSupply(), lmUSDT - redeemAmount - loanManager.escrowedMapleShares(address(lusdt)) * 10 ** 12
        );
        if (loanManager.escrowedMapleShares(address(lusdt)) == 0) {
            assertFalse(loanManager.awaitingRedemption(address(usdt)));
        } else {
            assertTrue(loanManager.awaitingRedemption(address(usdt)));
        }
        vm.stopPrank();
    }
}

contract TestGetter is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_getAssets_fuzz(uint256 lpTokens) external {
        vm.assume(lpTokens < 1e30);
        vm.assume(lpTokens > 0);
        assertEq(loanManager.getAssets(USDC, lpTokens), usdcPool.convertToAssets(lpTokens / 10 ** 12));
        assertEq(loanManager.getAssets(USDT, lpTokens), usdtPool.convertToAssets(lpTokens / 10 ** 12));
    }

    function test_getAssets_with_unrealisedLosses_fuzz(uint256 lpTokens) external {
        vm.assume(lpTokens < 1e30);
        vm.assume(lpTokens > 0);
        assertEq(
            loanManager.getAssetsWithUnrealisedLosses(USDC, lpTokens), usdcPool.convertToExitAssets(lpTokens / 10 ** 12)
        );
        assertEq(
            loanManager.getAssetsWithUnrealisedLosses(USDT, lpTokens), usdtPool.convertToExitAssets(lpTokens / 10 ** 12)
        );
    }

    function test_getShares_fuzz(uint256 amount) external {
        vm.assume(amount < 1e30);
        vm.assume(amount > 0);
        assertEq(loanManager.getShares(USDC, amount), usdcPool.convertToShares(amount));
        assertEq(loanManager.getShares(USDT, amount), usdtPool.convertToShares(amount));
    }

    function test_getExitShares_fuzz(uint256 amount) external {
        vm.assume(amount < 1e30);
        vm.assume(amount > 0);
        assertEq(loanManager.getExitShares(USDC, amount), usdcPool.convertToExitShares(amount));
        assertEq(loanManager.getExitShares(USDT, amount), usdtPool.convertToExitShares(amount));
    }

    function test_getUnrealisedLosses_Maple() external {
        assertEq(loanManager.getUnrealizedLossesMaple(USDC), usdcPool.unrealizedLosses());
        assertEq(loanManager.getUnrealizedLossesMaple(USDT), usdtPool.unrealizedLosses());
    }

    function test_previewDepositAssets_fuzz(uint256 amount) external {
        _setAllowedLender(poolDelegateUSDC);
        _setAllowedLender(poolDelegateUSDT);
        uint256 maxDeposit = usdcPool.maxDeposit(address(loanManager));
        // console.log(maxDeposit);
        vm.assume(amount < maxDeposit);
        vm.assume(amount > 0);

        uint256 totalSupply = usdcPool.totalSupply();
        uint256 totalAssets = usdcPool.totalAssets();
        uint256 sharesToMint = loanManager.previewDepositAssets(USDC, amount);

        if (totalSupply == 0) {
            assertEq(sharesToMint, amount);
        } else if (totalAssets != 0) {
            assertEq(sharesToMint, amount * totalSupply / totalAssets);
        }

        totalSupply = usdtPool.totalSupply();
        totalAssets = usdtPool.totalAssets();
        sharesToMint = loanManager.previewDepositAssets(USDT, amount);
        if (totalSupply == 0) {
            assertEq(sharesToMint, amount);
        } else if (totalAssets != 0) {
            assertEq(sharesToMint, amount * totalSupply / totalAssets);
        }
    }
}
