// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../helpers/BaseTest.t.sol";

contract TestProxy is BaseTest {

    function setUp() public virtual override{
        super.setUp();
    }

    function test_proxy() external {
        assertEq(loanManager.aclManager(), address(aclManager));
        assertEq(loanManager.nstblHub(), NSTBL_HUB);
        assertEq(loanManager.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager.usdc(), USDC);
        assertEq(loanManager.MAPLE_POOL_MANAGER_USDC(), MAPLE_POOL_MANAGER_USDC);
        assertEq(loanManager.MAPLE_WITHDRAWAL_MANAGER_USDC(), WITHDRAWAL_MANAGER_USDC);
        assertEq(uint256(vm.load(address(loanManager), bytes32(uint256(61)))), 1);
        assertEq(uint256(vm.load(address(loanManager), bytes32(uint256(0)))), 111);
        assertEq(loanManager.getVersion(), 111);
        assertEq(loanManager.versionSlot(), 111);
        assertEq(ERC20(address(loanManager.lUSDC())).name(), "Loan Manager USDC");
    }
    
    function test_wrongProxyUpgrade() external {
         
        vm.startPrank(proxyAdmin.owner());
        bytes memory data = abi.encodeCall(lmImpl2.initialize, (1e3));
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(loanManagerProxy)), address(lmImpl2), data);
        vm.stopPrank();

        LoanManagerV2 loanManager2 = LoanManagerV2(address(loanManagerProxy));
        assertEq(loanManager2.aclManager(), address(aclManager));
        assertEq(loanManager2.nstblHub(), NSTBL_HUB);
        assertEq(loanManager2.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager2.usdc(), USDC);
        assertEq(loanManager2.MAPLE_POOL_MANAGER_USDC(), MAPLE_POOL_MANAGER_USDC);
        assertEq(loanManager2.MAPLE_WITHDRAWAL_MANAGER_USDC(), WITHDRAWAL_MANAGER_USDC);
        assertEq(uint256(vm.load(address(loanManager2), bytes32(uint256(0)))), 222);
        assertEq(loanManager2.getVersion(), 222);
        assertEq(loanManager2.versionSlot(), 222);
        assertEq(ERC20(address(loanManager2.lUSDC())).name(), "Loan Manager USDC");
        assertEq(loanManager2.newVar(), 1e3);
        assertEq(loanManager2.getLocked(), 0, "LOCKED VAR");
        assertEq(uint256(vm.load(address(loanManager2), bytes32(uint256(62)))), 0, "T2");
 
    }
}

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
        vm.warp(block.timestamp+ 1);
        uint256 maturedAssets = loanManager.getMaturedAssets();
        console.log("Matured Assets", maturedAssets);
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
        _investAssets(USDC, address(usdcPool), amount);

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

        _investAssets(USDC, address(usdcPool), amount);
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
        _investAssets(USDC, address(usdcPool), amount);

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
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        console.log("lUSDC minted - ", lmUSDC);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(lmUSDC);
        loanManager.redeem();
        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares() * 10 ** 12);
        assertEq(lusdc.totalSupply(), loanManager.escrowedMapleShares() * 10 ** 12);
        console.log("lUSDC pending redemption - ", loanManager.getLpTokensPendingRedemption());
        if (loanManager.escrowedMapleShares() == 0) {
            assertFalse(loanManager.awaitingRedemption());
        } else {
            assertTrue(loanManager.awaitingRedemption());
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
        loanManager.requestRedeem(lmUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), lmUSDC);
        assertEq(lusdc.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(lmUSDC);
        loanManager.redeem();
        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares() * 10 ** 12);
        assertEq(lusdc.totalSupply(), loanManager.escrowedMapleShares() * 10 ** 12);
        if (loanManager.escrowedMapleShares() == 0) {
            assertFalse(loanManager.awaitingRedemption());
        } else {
            assertTrue(loanManager.awaitingRedemption());
        }
        vm.stopPrank();
    }

    function test_redeem_USDC_partialLP_pass_fuzz(uint256 amount, uint256 redeemAmount) external {
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
        loanManager.requestRedeem(redeemAmount);

        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12, "loanmanager");
        assertEq(redeemAmount, loanManager.escrowedMapleShares() * 1e12);

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(redeemAmount);
        loanManager.redeem();
        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(
            lusdc.balanceOf(NSTBL_HUB),
            lmUSDC - (redeemAmount - loanManager.escrowedMapleShares() * 10 ** 12)
        );
        assertEq(
            lusdc.totalSupply(), lmUSDC - (redeemAmount - loanManager.escrowedMapleShares() * 10 ** 12)
        );
        if (loanManager.escrowedMapleShares() == 0) {
            assertFalse(loanManager.awaitingRedemption());
        } else {
            assertTrue(loanManager.awaitingRedemption());
        }
        vm.stopPrank();
    }

    function test_redeem_USDC_missedWindow() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);
        uint256 wmInitialBal = usdcPool.balanceOf(address(withdrawalManagerUSDC));
        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        console.log("lUSDC minted - ", lmUSDC);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (, uint256 exitWindowEnd) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();

        vm.warp(exitWindowEnd + 100);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), wmInitialBal + lmUSDC / 10 ** 12);

        //removing shares
        loanManager.remove();
        assertEq(usdcPool.balanceOf(address(loanManager)), lmUSDC / 10 ** 12);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), wmInitialBal);
        assertEq(loanManager.escrowedMapleShares(), 0);
        assertEq(loanManager.awaitingRedemption(), false);

        //Requesting redemption again
        loanManager.requestRedeem(lmUSDC);
        assertEq(usdcPool.balanceOf(address(loanManager)), 0);
        assertEq(usdcPool.balanceOf(address(withdrawalManagerUSDC)), wmInitialBal + lmUSDC / 10 ** 12);

        _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        //Redeeming requested assets
        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(lmUSDC);
        loanManager.redeem();

        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(lusdc.balanceOf(NSTBL_HUB), loanManager.escrowedMapleShares() * 10 ** 12);
        assertEq(lusdc.totalSupply(), loanManager.escrowedMapleShares() * 10 ** 12);
        console.log("lUSDC pending redemption - ", loanManager.getLpTokensPendingRedemption());
        if (loanManager.escrowedMapleShares() == 0) {
            assertFalse(loanManager.awaitingRedemption());
        } else {
            assertTrue(loanManager.awaitingRedemption());
        }
        vm.stopPrank();
    }

    function test_redeem_USDC_partialLP_missedWindow_fuzz(uint256 amount, uint256 redeemAmount) external {
        // Constraint input amount
        vm.assume(amount < _getUpperBoundDeposit(MAPLE_USDC_CASH_POOL, address(poolManagerUSDC)));
        uint256 shares = usdcPool.previewDeposit(amount);
        vm.assume(shares > 0);
        _investAssets(USDC, address(usdcPool), amount);

        vm.assume(redeemAmount < IPool(MAPLE_USDC_CASH_POOL).balanceOf(address(loanManager)));
        redeemAmount *= 1e12;
        vm.assume(redeemAmount > 0);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        uint256 wmBalBefore = usdcPool.balanceOf(address(withdrawalManagerUSDC));
        console.log("lUSDC minted - ", lmUSDC);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(redeemAmount);
        uint256 wmBalAfter = usdcPool.balanceOf(address(withdrawalManagerUSDC));

        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12);
        assertEq(redeemAmount, loanManager.escrowedMapleShares() * 1e12);
        assertEq(wmBalAfter-wmBalBefore, redeemAmount / 1e12);
        console.log(redeemAmount, redeemAmount / 1e12);

        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (, uint256 exitWindowEnd) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();

        vm.warp(exitWindowEnd + 100);

        vm.expectRevert("LM: Not in Window");
        loanManager.redeem();
        assertEq(wmBalAfter-wmBalBefore, redeemAmount / 10 ** 12);

        //removing shares
        wmBalBefore = usdcPool.balanceOf(address(withdrawalManagerUSDC));
        loanManager.remove();
        wmBalAfter = usdcPool.balanceOf(address(withdrawalManagerUSDC));
        assertEq(usdcPool.balanceOf(address(loanManager)), lmUSDC / 10 ** 12);
        assertEq(wmBalBefore-wmBalAfter, redeemAmount / 10 ** 12);
        assertEq(loanManager.escrowedMapleShares(), 0);
        assertEq(loanManager.awaitingRedemption(), false);

        //Requesting redemption again
        wmBalBefore = usdcPool.balanceOf(address(withdrawalManagerUSDC));
        loanManager.requestRedeem(redeemAmount);
        wmBalAfter = usdcPool.balanceOf(address(withdrawalManagerUSDC));
        assertEq(usdcPool.balanceOf(address(loanManager)), (lmUSDC - redeemAmount) / 1e12);
        assertEq(wmBalAfter-wmBalBefore, redeemAmount / 10 ** 12);

        _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        uint256 usdcBal1 = usdc.balanceOf(NSTBL_HUB);
        vm.warp(exitWindowStart);

        //Redeeming requested assets
        uint256 expectedUSDC = loanManager.getAssetsWithUnrealisedLosses(redeemAmount);
        loanManager.redeem();

        uint256 usdcBal2 = usdc.balanceOf(NSTBL_HUB);
        console.log(usdcBal2 - usdcBal1, expectedUSDC);
        assertEq(
            lusdc.balanceOf(NSTBL_HUB),
            lmUSDC - (redeemAmount - loanManager.escrowedMapleShares() * 10 ** 12)
        );
        assertEq(
            lusdc.totalSupply(), lmUSDC - (redeemAmount - loanManager.escrowedMapleShares() * 10 ** 12)
        );
        console.log("lUSDC pending redemption - ", loanManager.getLpTokensPendingRedemption());

        if (loanManager.escrowedMapleShares() == 0) {
            assertFalse(loanManager.awaitingRedemption());
        } else {
            assertTrue(loanManager.awaitingRedemption());
        }
        vm.stopPrank();
    }
    function test_redeem_USDC_withoutRequest() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        // time warp
        vm.warp(block.timestamp + 2 weeks);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        console.log("lUSDC minted - ", lmUSDC);
        vm.startPrank(NSTBL_HUB);

        vm.expectRevert("LM: No redemption requested");
        loanManager.redeem();

        vm.stopPrank();
    }
}

contract TestGetter is BaseTest {
    function setUp() public override {
        super.setUp();
    }
   
    function test_getAssets_with_unrealisedLosses_fuzz(uint256 lpTokens) external {
        vm.assume(lpTokens < 1e30);
        vm.assume(lpTokens > 0);
        assertEq(
            loanManager.getAssetsWithUnrealisedLosses(lpTokens), usdcPool.convertToExitAssets(lpTokens / 10 ** 12)
        );
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

    function test_getTotalAssetsMaple() external {
        console.log("Maple USDC assets - ", loanManager.getTotalAssetsMaple());
    }

    function test_previewRedeem_USDC() external {
        uint256 amount = 1e7 * 1e6;
        _investAssets(USDC, address(usdcPool), amount);

        uint256 lmUSDC = lusdc.balanceOf(NSTBL_HUB);
        vm.startPrank(NSTBL_HUB);
        loanManager.requestRedeem(lmUSDC);
        vm.stopPrank();

        assertEq(loanManager.previewRedeem(lmUSDC), 0);
        uint256 _currCycleId = withdrawalManagerUSDC.getCurrentCycleId();
        uint256 _exitCycleId = withdrawalManagerUSDC.exitCycleId(address(loanManager));
        assertEq(_exitCycleId, _currCycleId + 2);
        (uint256 exitWindowStart,) = withdrawalManagerUSDC.getWindowAtId(_exitCycleId);

        vm.warp(exitWindowStart);
        console.log("Assets available for Redemption: ", loanManager.previewRedeem(lmUSDC));
    }
    function test_IsValidDepositAmount_USDC_fuzz() external {
        assertTrue(loanManager.isValidDepositAmount(1e12, MAPLE_USDC_CASH_POOL, MAPLE_POOL_MANAGER_USDC));
    }
}
