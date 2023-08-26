// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { loanManager } from "../contracts/LoanManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPoolManager } from "../contracts/interfaces/IPoolManager.sol";
import { IWithdrawalManager } from "../contracts/interfaces/IWithdrawalManager.sol";
import { IPool } from "../contracts/interfaces/IPool.sol";

contract TestBase is Test{

     loanManager public loan;
    // Token public token;
    IERC20 public lusdc;
    IERC20 public usdc;
    IPool public pool;
    IPoolManager public poolManager;
    IWithdrawalManager public withdrawalManager;
    address public poolDelegate = 0x8c8C2431658608F5649B8432764a930c952d8A98;
    address owner = address(123);
    address user = address(456);

    function setUp() public virtual{
        vm.label(poolDelegate, "poolDelegate");

        vm.startPrank(owner);
        // token = new Token(name, symbol);
        loan = new loanManager(0x749f88e87EaEb030E478164cFd3681E27d0bcB42,
                                0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92,
                                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                                owner);
        vm.stopPrank();
        vm.label(address(loan), "loanManager");
        lusdc = IERC20(loan.lUSDCAdd());
        usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        vm.label(address(usdc), "USDC");
        pool = IPool(0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92);
        vm.label(address(pool), "Pool");
        poolManager = IPoolManager(0x219654A61a0BC394055652986BE403fa14405Bb8);
        vm.label(address(poolManager), "poolManager");
        withdrawalManager = IWithdrawalManager(0x1146691782c089bCF0B19aCb8620943a35eebD12);
    }
}
contract BasicTests is TestBase {


    function setUp() public override{
        super.setUp();
    }

    function testInvest() public {
        vm.prank(owner);
        loan.setAuthorizedCaller(user);

        deal(address(usdc), user, 1e7 * 1e6, true);
        assertEq(usdc.balanceOf(user), 1e7 * 1e6);

        //first whitelist user
        vm.startPrank(poolDelegate);
        poolManager.setAllowedLender(address(loan), true);
        (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        assertTrue(out);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(loan), 1e7 * 1e6);
        console.log("Deposit Preview: ", pool.previewDeposit(1e7 * 1e6));
        loan.investUSDCMapleCash(1e7 * 1e6);
        assertEq(usdc.balanceOf(user), 0);
        console.log("Maple USDC shares balance: ", pool.balanceOf(address(loan)));
        // console.log("LM lUSDC minted to nstblHub: ", lusdc.balanceOf(0x749f88e87EaEb030E478164cFd3681E27d0bcB42));
        console.log("LM lUSDC minted to nstblHub: ", lusdc.balanceOf(address(loan)));
        console.log(lusdc.totalSupply());
        vm.stopPrank();
    }

     function testRedeemRequest() public {

        vm.prank(owner);
        loan.setAuthorizedCaller(user);

        deal(address(usdc), user, 1e7 * 1e6, true);
        assertEq(usdc.balanceOf(user), 1e7 * 1e6);

        //first whitelist user
        vm.startPrank(poolDelegate);
        poolManager.setAllowedLender(address(loan), true);
        (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        assertTrue(out);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(loan), 1e7 * 1e6);
        loan.investUSDCMapleCash(1e7 * 1e6);
        assertEq(usdc.balanceOf(user),0);
        console.log("LP balance", pool.balanceOf(address(loan)));


        uint256 lusdcLPTokens = lusdc.totalSupply();
        console.log("Shares converted to assets before warp: ", loan.getAssets(lusdcLPTokens));
        console.log("Shares converted to exit assets before warp: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));

        //time warp
        vm.warp(block.timestamp + 100 days);

        console.log("Shares converted to assets after 100 days: ", loan.getAssets(lusdcLPTokens));
        console.log("Shares converted to exit assets after 100 days: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));
        
        //requesting redeem
        loan.requestRedeemUSDCMapleCash(lusdcLPTokens);
         //preview redemption
        uint256 b = loan.previewRedeemAsset(lusdcLPTokens);
        console.log("Resulting assets: ", b);
        // // console.log("Escrow Shares: ", escrowShares);
        assertEq(pool.balanceOf(address(loan)), 0);
        vm.stopPrank();

    }

    //  function testRedeem() public {

    //     vm.prank(owner);
    //     loan.setAuthorizedCaller(user);

    //     deal(address(usdc), user, 1e7 * 1e6, true);
    //     assertEq(usdc.balanceOf(user), 1e7 * 1e6);

    //     //first whitelist user
    //     vm.startPrank(poolDelegate);
    //     poolManager.setAllowedLender(address(loan), true);
    //     (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
    //     assertTrue(out);
    //     vm.stopPrank();

    //     vm.startPrank(user);
    //     usdc.approve(address(loan), 1e7 * 1e6);
    //     loan.investUSDCMapleCash(1e7 * 1e6);
    //     assertEq(usdc.balanceOf(user),0);
    //     console.log("LP balance", pool.balanceOf(address(loan)));


    //     uint256 lusdcLPTokens = lusdc.totalSupply();
    //     console.log("Shares converted to assets before warp: ", loan.getAssets(lusdcLPTokens));
    //     console.log("Shares converted to exit assets before warp: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));

    //     //time warp
    //     vm.warp(block.timestamp + 100 days);

    //     console.log("Shares converted to assets after 100 days: ", loan.getAssets(lusdcLPTokens));
    //     console.log("Shares converted to exit assets after 100 days: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));
        
    //     //requesting redeem
    //     loan.requestRedeemUSDCMapleCash(lusdcLPTokens);
    //      //preview redemption
    //     uint256 b = loan.previewRedeemAsset(lusdcLPTokens);
    //     console.log("Resulting assets: ", b);
    //     // // console.log("Escrow Shares: ", escrowShares);
    //     assertEq(pool.balanceOf(address(loan)), 0);
    //     // vm.expectRevert();
    //     // loan.redeemUSDCMapleCash();

    //     vm.warp(block.timestamp + 7 days);
    //     loan.redeemUSDCMapleCash();

    //     vm.stopPrank();

    // }
}

contract RedeemTests is TestBase {

    function setUp() public override{
        super.setUp();
    }

    function testRedeem_SingleRedemption_withinWindow() external{

        vm.prank(owner);
        loan.setAuthorizedCaller(user);

        deal(address(usdc), user, 1e6 * 1e6, true);
        assertEq(usdc.balanceOf(user), 1e6 * 1e6);

        //first whitelist user
        vm.startPrank(poolDelegate);
        poolManager.setAllowedLender(address(loan), true);
        (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        assertTrue(out);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(loan), 1e6 * 1e6);
        loan.investUSDCMapleCash(1e6 * 1e6);
        assertEq(usdc.balanceOf(user),0);
        console.log("LP balance", pool.balanceOf(address(loan)));

        uint256 lusdcLPTokens = lusdc.totalSupply();
        console.log("Shares converted to assets before warp: ", loan.getAssets(lusdcLPTokens));
        console.log("Shares converted to exit assets before warp: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));

        //time warp
        vm.warp(block.timestamp + 2 weeks);

        console.log("Shares converted to assets after 2 weeks: ", loan.getAssets(lusdcLPTokens));
        console.log("Shares converted to exit assets after 2 weeks: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));
        
        assertEq(withdrawalManager.exitCycleId(address(loan)), 0);

        uint256 _currCycleId =withdrawalManager.getCurrentCycleId();
        //requesting redeem
        // vm.expectRevert();
        loan.requestRedeemUSDCMapleCash(lusdcLPTokens);
        // loan.requestRedeemUSDCMapleCash(lusdcLPTokens);
    
        uint256 _exitCycleId = withdrawalManager.exitCycleId(address(loan));

        assertEq(_exitCycleId, _currCycleId+2);
        (uint256 exitWindowStart, ) = withdrawalManager.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loan.redeemUSDCMapleCash();

        uint256 usdcBal1 = usdc.balanceOf(user);
        vm.warp(exitWindowStart);
        uint256 expectedUSDC = loan.getAssetsWithUnrealisedLosses(lusdcLPTokens);
        loan.redeemUSDCMapleCash();
        uint256 usdcBal2 = usdc.balanceOf(user);
        console.log(usdcBal2-usdcBal1, expectedUSDC);
        console.log((usdcBal2-usdcBal1)-expectedUSDC);

        vm.stopPrank();

    
    }

    function testRedeem_MultipleRedemption_withinWindow() external{

        vm.prank(owner);
        loan.setAuthorizedCaller(user);

        deal(address(usdc), user, 1e6 * 1e6, true);
        assertEq(usdc.balanceOf(user), 1e6 * 1e6);

        //first whitelist user
        vm.startPrank(poolDelegate);
        poolManager.setAllowedLender(address(loan), true);
        (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        assertTrue(out);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(loan), 1e6 * 1e6);
        loan.investUSDCMapleCash(1e6 * 1e6);
        assertEq(usdc.balanceOf(user),0);
        console.log("LP balance", pool.balanceOf(address(loan)));

        uint256 lusdcLPTokens = lusdc.totalSupply();
        console.log("Shares converted to assets before warp: ", loan.getAssets(lusdcLPTokens));
        console.log("Shares converted to exit assets before warp: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));

        //time warp
        vm.warp(block.timestamp + 2 weeks);

        console.log("Shares converted to assets after 2 weeks: ", loan.getAssets(lusdcLPTokens));
        console.log("Shares converted to exit assets after 2 weeks: ", loan.getAssetsWithUnrealisedLosses(lusdcLPTokens));
        
        assertEq(withdrawalManager.exitCycleId(address(loan)), 0);

        uint256 lpTokens1 = (lusdcLPTokens*60)/100;
        uint256 lpTokens2 = lusdcLPTokens-lpTokens1;

        uint256 _currCycleId =withdrawalManager.getCurrentCycleId();
        //requesting redeem
        loan.requestRedeemUSDCMapleCash(lpTokens1);

        uint256 _exitCycleId = withdrawalManager.exitCycleId(address(loan));

        assertEq(_exitCycleId, _currCycleId+2);
        (uint256 exitWindowStart, ) = withdrawalManager.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loan.redeemUSDCMapleCash();

        uint256 usdcBal1 = usdc.balanceOf(user);
        uint256 expectedUSDC = loan.getAssetsWithUnrealisedLosses(lpTokens1);
        vm.warp(exitWindowStart);
        loan.redeemUSDCMapleCash();
        uint256 usdcBal2 = usdc.balanceOf(user);
        console.log(usdcBal2-usdcBal1, expectedUSDC);
        console.log((usdcBal2-usdcBal1)-expectedUSDC);

        _currCycleId =withdrawalManager.getCurrentCycleId();
        //requesting redeem
        loan.requestRedeemUSDCMapleCash(lpTokens2);

        _exitCycleId = withdrawalManager.exitCycleId(address(loan));

        assertEq(_exitCycleId, _currCycleId+2);
        (exitWindowStart, ) = withdrawalManager.getWindowAtId(_exitCycleId);

        vm.expectRevert("WM:PE:NOT_IN_WINDOW");
        loan.redeemUSDCMapleCash();

        usdcBal1 = usdc.balanceOf(user);
        vm.warp(exitWindowStart);
        expectedUSDC = loan.getAssetsWithUnrealisedLosses(lpTokens2);
        loan.redeemUSDCMapleCash();
        usdcBal2 = usdc.balanceOf(user);
        console.log(usdcBal2-usdcBal1, expectedUSDC);
        console.log((usdcBal2-usdcBal1)-expectedUSDC);
        
        console.log(pool.balanceOf(address(loan)));
        vm.stopPrank();

    
    }

}

// contract FailureTests is BasicTests {

//     function setUp() public override {

//     }

// }

