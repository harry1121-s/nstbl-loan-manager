// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../helpers/BaseTest.t.sol";

contract TestProxy is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_proxy() external {
        assertEq(loanManager.aclManager(), address(aclManager));
        assertEq(loanManager.nstblHub(), NSTBL_HUB);
        assertEq(loanManager.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager.usdc(), USDC);
        assertEq(loanManager.MAPLE_POOL_MANAGER_USDC(), MAPLE_POOL_MANAGER_USDC);
        assertEq(loanManager.MAPLE_WITHDRAWAL_MANAGER_USDC(), WITHDRAWAL_MANAGER_USDC);
        assertEq(uint256(vm.load(address(loanManager), bytes32(uint256(0)))), 1);
        assertEq(loanManager.getVersion(), 1);
        assertEq(loanManager.versionSlot(), 1);
        assertEq(ERC20(address(loanManager.lUSDC())).name(), "Loan Manager USDC");
    }

    function test_wrongSetup() external {
        vm.startPrank(aclManager.admin());
        vm.expectRevert("LM:INVALID_ADDRESS");
        loanManager.updateNSTBLHUB(address(0));
        vm.stopPrank();

        LoanManager imp1 = new LoanManager();

        bytes memory data = abi.encodeCall(imp1.initialize, (address(0), address(0)));

        vm.expectRevert("LM:INVALID_ADDRESS");
        TransparentUpgradeableProxy lmProxy = new TransparentUpgradeableProxy(address(imp1), address(proxyAdmin), data);
    }
}

contract TestDeposit is BaseTest {
    using SafeERC20 for IERC20;

    function setUp() public virtual override {
        super.setUp();
    }

    function test_deposit_pass_USDC() public {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, amount);

        uint256 sharesToReceive = usdcPool.previewDeposit(amount);
        assertEq(IERC20(USDC).balanceOf(user), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), sharesToReceive);
        vm.warp(block.timestamp + 1);
        uint256 maturedAssets = loanManager.getMaturedAssets();
        console.log("Matured Assets", maturedAssets);
    }

    function test_deposit_pass_USDC_fuzz(uint256 amount) public {
        // Constraint input amount
        vm.assume(amount < loanManager.getDepositUpperBound());
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        // Action
        _investAssets(USDC, amount);

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
        _investAssets(USDC, amount);
    }
}

contract TestRequestRedeem is BaseTest {
    using SafeERC20 for IERC20;

    function setUp() public override {
        super.setUp();
    }

    function test_requestRedeem_USDC() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        vm.expectRevert("LM: Insufficient Shares");
        loanManager.requestRedeem((lmUSDC * 11) / 10);

        loanManager.requestRedeem(lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        vm.stopPrank();
    }

    function test_requestRedeem_and_deposit_USDC() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);

        vm.expectRevert("LM: No redemption requested");
        loanManager.redeem();

        loanManager.requestRedeem(lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertTrue(loanManager.awaitingRedemption());
        vm.stopPrank();
        _investAssets(USDC, amount);
    }

    function test_requestRedeem_USDC_fullLP_pass_fuzz(uint256 amount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        vm.stopPrank();
    }

    function test_requestRedeem_USDC_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, amount);
        vm.assume(redeemAmount < IPool(MAPLE_USDC_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(redeemAmount);

        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12, "loanmanager");
        vm.stopPrank();
    }

    function test_requestRedeem_USDC_revert_pendingRedemption() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC / 2);

        vm.expectRevert("LM: Redemption Pending");
        loanManager.requestRedeem(lmUSDC / 2);

        vm.stopPrank();
    }
}

contract TestRedeem is BaseTest {
    using SafeERC20 for IERC20;

    function test_redeem_USDC() external {
        uint256 amount = 1e4 * 1e6;
        _investAssets(USDC, amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        // vm.expectRevert("LM: No redemption requested");
        // loanManager.getRedemptionWindow();
        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        (, uint256 lockedShares) =
            withdrawalManagerUSDC.requests(withdrawalManagerUSDC.requestIds(address(loanManager)));
        console.log("Shares: ", lmUSDC, lockedShares, withdrawalManagerUSDC.lockedShares(address(loanManager)));
        console.log("Request Id: ", withdrawalManagerUSDC.requestIds(address(loanManager)));
        console.log("Manual Shares: ", withdrawalManagerUSDC.manualSharesAvailable(address(loanManager)));
        console.log("If manual withdraw: ", withdrawalManagerUSDC.isManualWithdrawal(address(loanManager)));
        console.log("If in exit window: ", withdrawalManagerUSDC.isInExitWindow(address(loanManager)));

        vm.stopPrank();

        vm.warp(block.timestamp + 100 days);
        // auto redemption
        uint256 balBefore = IERC20(USDC).balanceOf(NSTBL_HUB);
        vm.prank(poolDelegateUSDC);
        withdrawalManagerUSDC.processRedemptions(lmUSDC / 10 ** 12);
        uint256 balAfter = IERC20(USDC).balanceOf(NSTBL_HUB);

        console.log("If in exit window: ", withdrawalManagerUSDC.isInExitWindow(address(loanManager)));
        console.log("USDC balances: ", balBefore, balAfter);
        console.log("Manual Shares: ", withdrawalManagerUSDC.manualSharesAvailable(address(loanManager)));
        console.log("Locked Shares: ", withdrawalManagerUSDC.lockedShares(address(loanManager)));
        console.log("Request Id: ", withdrawalManagerUSDC.requestIds(address(loanManager)));
        (, lockedShares) =
            withdrawalManagerUSDC.requests(withdrawalManagerUSDC.requestIds(address(loanManager)));

        console.log("Pending shares: ", lockedShares);

        //now performing manual redeem
        vm.startPrank(NSTBL_HUB);
        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(lmUSDC);
        if(withdrawalManagerUSDC.lockedShares(address(loanManager)) != 0)
        {
            uint256 stablesRedeemed = loanManager.redeem();
            console.log(stablesRedeemed, expectedUSDC, "check stables received");
            if(loanManager.awaitingRedemption()){
                assertFalse(stablesRedeemed == expectedUSDC);
                assertEq(loanManager.escrowedMapleShares(), lockedShares);
            }
            else{
                assertEq(stablesRedeemed, expectedUSDC, "check stables received");
            }

            console.log("Request Id: ", withdrawalManagerUSDC.requestIds(address(loanManager)));
            console.log("If in exit window: ", withdrawalManagerUSDC.isInExitWindow(address(loanManager)));
            console.log("Manual Shares: ", withdrawalManagerUSDC.manualSharesAvailable(address(loanManager)));
        }
        vm.stopPrank();

    }

    function test_redeem_USDC_fullLP_pass_fuzz(uint256 amount) external {
        // Constraint input amount
        // vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        vm.assume(amount < 1e5 * 1e6);
        vm.assume(amount > 1e2 * 1e6);

        _investAssets(USDC, amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);

        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        vm.stopPrank();

        vm.prank(poolDelegateUSDC);
        withdrawalManagerUSDC.processRedemptions(lmUSDC / 10 ** 12);
        vm.warp(block.timestamp + 100 days);
        uint256 availableShares = withdrawalManagerUSDC.lockedShares(address(loanManager));
        (, uint256 lockedShares) =
            withdrawalManagerUSDC.requests(withdrawalManagerUSDC.requestIds(address(loanManager)));
        assertEq(lockedShares + availableShares, lmUSDC/1e12);

        vm.startPrank(NSTBL_HUB);
        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(lmUSDC);

        if(withdrawalManagerUSDC.lockedShares(address(loanManager)) != 0)
        {
             uint256 stablesRedeemed = loanManager.redeem();
            if(loanManager.awaitingRedemption()){
                assertFalse(stablesRedeemed == expectedUSDC);
                assertEq(loanManager.escrowedMapleShares(), lockedShares);
                assertEq(lusdc.balanceOf(NSTBL_HUB)/1e12, lockedShares);
            }
            else{
                assertEq(lusdc.balanceOf(NSTBL_HUB), 0);
                assertEq(lusdc.totalSupply(), 0);
                assertEq(stablesRedeemed, expectedUSDC, "check stables received");
                assertEq(loanManager.getLpTokensPendingRedemption(), 0);
            }
    
        }
        vm.stopPrank();

       
    }

    function test_redeem_USDC_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);

        _investAssets(USDC, amount);
        vm.assume(redeemAmount < IPool(MAPLE_USDC_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);
        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        console.log(amount, redeemAmount, lmUSDC);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(redeemAmount);

        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12, "loanmanager");
        assertEq(redeemAmount, loanManager.escrowedMapleShares() * 1e12);
        vm.stopPrank();

        vm.prank(poolDelegateUSDC);
        withdrawalManagerUSDC.processRedemptions(redeemAmount / 10 ** 12);

        vm.warp(block.timestamp + 100 days);

        vm.startPrank(NSTBL_HUB);
        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(redeemAmount);
        uint256 usdcReceived = loanManager.redeem();
        assertEq(expectedUSDC, usdcReceived);
        console.log("USDC received: ", expectedUSDC, usdcReceived);

        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC - (redeemAmount - loanManager.escrowedMapleShares() * 10 ** 12));
        assertEq(lusdc.totalSupply(), lmUSDC - (redeemAmount - loanManager.escrowedMapleShares() * 10 ** 12));
        if (loanManager.escrowedMapleShares() == 0) {
            assertFalse(loanManager.awaitingRedemption());
        } else {
            assertTrue(loanManager.awaitingRedemption());
        }
        vm.stopPrank();
    }

    function test_remove_shares() external {
        _investAssets(USDC, 1e4 * 1e6);
        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        vm.prank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);

        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        (, uint256 lockedShares) =
            withdrawalManagerUSDC.requests(withdrawalManagerUSDC.requestIds(address(loanManager)));
        assertEq(lockedShares, lmUSDC / 1e12);

        vm.prank(NSTBL_HUB);
        loanManager.remove();
        assertEq(usdcPool.balanceOf(address(loanManager)), lmUSDC / 1e12);
        (, lockedShares) = withdrawalManagerUSDC.requests(withdrawalManagerUSDC.requestIds(address(loanManager)));
        assertEq(lockedShares, 0);
    }

    function test_remove_shares_fail() external {
        _investAssets(USDC, 1e4 * 1e6);
        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        vm.prank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);

        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        (, uint256 lockedShares) =
            withdrawalManagerUSDC.requests(withdrawalManagerUSDC.requestIds(address(loanManager)));
        assertEq(lockedShares, lmUSDC / 1e12);

        // auto redemption
        vm.prank(poolDelegateUSDC);
        withdrawalManagerUSDC.processRedemptions(lmUSDC / 10 ** 12);

        vm.startPrank(NSTBL_HUB);
        vm.expectRevert("LM: Not in Queue");
        loanManager.remove();
        vm.stopPrank();
    }

    function test_redeem_USDC_fail() external {
        uint256 amount = 1e4 * 1e6;
        _investAssets(USDC, amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        // vm.expectRevert("LM: No redemption requested");
        // loanManager.getRedemptionWindow();
        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        vm.stopPrank();

        //now performing manual redeem
        vm.startPrank(NSTBL_HUB);
        vm.expectRevert("LM: No shares to redeem");
        uint256 stablesRedeemed = loanManager.redeem();
        vm.stopPrank();
    }

    function test_redeem_USDC_withoutRequest_revert() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        vm.startPrank(NSTBL_HUB);

        vm.expectRevert("LM: No redemption requested");
        loanManager.redeem();

        vm.stopPrank();
    }

    function test_remove_USDC_withoutRequest_revert() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        vm.startPrank(NSTBL_HUB);

        vm.expectRevert("LM: No Tokens to remove");
        loanManager.remove();

        vm.stopPrank();
    }
}

contract TestGetter is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_airdroppedTokens() external {
        deal(USDC, address(loanManager), 1e7 * 1e6, true);
        assertEq(loanManager.getAirdroppedTokens(USDC), 1e7 * 1e6);
        vm.prank(NSTBL_HUB);
        loanManager.withdrawTokens(USDC, 1e7 * 1e6, user1);
        assertEq(IERC20(USDC).balanceOf(user1), 1e7 * 1e6);
    }

    function test_LPTotalSupply() external {
        _investAssets(USDC, 1e12);
        assertEq(loanManager.getLPTotalSupply(), usdcPool.balanceOf(address(loanManager)) * 1e12);
    }

    function test_getAssets(uint256 lpTokens) external {
        vm.assume(lpTokens < 1e30);
        vm.assume(lpTokens > 0);
        assertEq(loanManager.getAssets(lpTokens), usdcPool.convertToAssets(lpTokens / 1e12));
    }

    function test_getAssets_with_unrealisedLosses_fuzz(uint256 lpTokens) external {
        vm.assume(lpTokens < 1e30);
        vm.assume(lpTokens > 0);
        assertEq(loanManager.getAssetsWithUnrealisedLosses(lpTokens), usdcPool.convertToExitAssets(lpTokens / 10 ** 12));
    }

    function test_getShares_fuzz(uint256 amount) external {
        vm.assume(amount < 1e30);
        vm.assume(amount > 0);
        assertEq(loanManager.getShares(amount), usdcPool.convertToShares(amount));
    }

    function test_getExitShares_fuzz(uint256 amount) external {
        vm.assume(amount < 1e30);
        vm.assume(amount > 0);
        assertEq(loanManager.getExitShares(amount), usdcPool.convertToExitShares(amount));
    }

    function test_getUnrealisedLosses_Maple() external {
        assertEq(loanManager.getUnrealizedLossesMaple(), usdcPool.unrealizedLosses());
    }

    function test_previewDepositAssets_fuzz(uint256 amount) external {
        _setAllowedLender(poolDelegateUSDC);
        uint256 maxDeposit = usdcPool.maxDeposit(address(loanManager));
        vm.assume(amount < maxDeposit);
        vm.assume(amount > 0);

        uint256 totalSupply = usdcPool.totalSupply();
        uint256 totalAssets = usdcPool.totalAssets();
        uint256 sharesToMint = loanManager.previewDepositAssets(amount);

        if (totalSupply == 0) {
            assertEq(sharesToMint, amount);
        } else if (totalAssets != 0) {
            assertEq(sharesToMint, amount * totalSupply / totalAssets);
        }

        totalSupply = usdcPool.totalSupply();
        totalAssets = usdcPool.totalAssets();
        sharesToMint = loanManager.previewDepositAssets(amount);
        if (totalSupply == 0) {
            assertEq(sharesToMint, amount);
        } else if (totalAssets != 0) {
            assertEq(sharesToMint, amount * totalSupply / totalAssets);
        }
    }

    function test_getTotalAssetsMaple() external view {
        console.log("Maple USDC assets - ", loanManager.getTotalAssetsMaple());
    }

    function test_previewRedeem_USDC() external {
        uint256 amount = 1e5 * 1e6;
        _investAssets(USDC, amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        vm.stopPrank();
        vm.warp(block.timestamp + 100 days);
        assertEq(loanManager.previewRedeem(lmUSDC), 0);
        // uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        // uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        // assertEq(_exitCycleId, _currCycleId + 2);
        // (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        // vm.warp(exitWindowStart);
        vm.prank(poolDelegateUSDC);
        withdrawalManagerUSDC.processRedemptions(lmUSDC / 10 ** 12);
        console.log("Assets available for Redemption: ", loanManager.previewRedeem(lmUSDC));
    }

    function test_IsValidDepositAmount_USDC_fuzz() external {
        assertTrue(loanManager.isValidDepositAmount(1e12));
        assertFalse(loanManager.isValidDepositAmount(1e15));
    }
}
