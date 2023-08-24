// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {loanManager} from "../contracts/LoanManager.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IPoolManager} from "../contracts/interfaces/IPoolManager.sol";
// import {IPool} from "../contracts/interfaces/IPool.sol";


// contract CounterTest is Test {

//     loanManager public loan;
//     IERC20 public usdc;
//     IPool public pool;
//     IPoolManager public poolManager;
//     address public poolDelegate = 0x8c8C2431658608F5649B8432764a930c952d8A98;
//     address owner = address(123);
//     address user = address(456);


//     function setUp() public {
//         vm.label(poolDelegate, "poolDelegate");

//         vm.startPrank(owner);
//         loan = new loanManager(0x749f88e87EaEb030E478164cFd3681E27d0bcB42, 
//                                 0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92, 
//                                 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
//         vm.stopPrank();
//         vm.label(address(loan), "loanManager");
        
//         usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
//         vm.label(address(usdc), "USDC");
//         pool = IPool(0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92);
//         vm.label(address(pool), "Pool");
//         poolManager = IPoolManager(0x219654A61a0BC394055652986BE403fa14405Bb8);
//         vm.label(address(poolManager), "poolManager");
        
//     }

//     function testInvest() public {

//         vm.prank(owner);
//         loan.setAuthorizedCaller(user);

//         deal(address(usdc), user, 1e7 * 1e6, true);
//         assertEq(usdc.balanceOf(user), 1e7 * 1e6);

//         //first whitelist user
//         vm.startPrank(poolDelegate);
//         poolManager.setAllowedLender(address(loan), true);
//         (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
//         assertTrue(out);
//         // vm.store(address(poolManager), bytes32(uint256(0x09)), bytes1(0x00));
//         // (bool out2,) = address(poolManager).staticcall(abi.encodeWithSignature("openToPublic()"));
//         // console.log("out - ",out2);
//         // // assertFalse(out2);
//         vm.stopPrank();

//         vm.startPrank(user);
//         usdc.approve(address(loan), 1e7 * 1e6);
//         loan.investUSDCMapleCash(1e7 * 1e6);
//         assertEq(usdc.balanceOf(user),0);
//         console.log("LP balance", pool.balanceOf(address(loan)));
//         uint256 shares = pool.balanceOf(address(loan));
//         vm.stopPrank();
    
//     }

//      function testRedeemRequest() public {

//         vm.prank(owner);
//         loan.setAuthorizedCaller(user);

//         deal(address(usdc), user, 1e7 * 1e6, true);
//         assertEq(usdc.balanceOf(user), 1e7 * 1e6);

//         //first whitelist user
//         vm.startPrank(poolDelegate);
//         poolManager.setAllowedLender(address(loan), true);
//         (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
//         assertTrue(out);
//         // vm.store(address(poolManager), bytes32(uint256(0x09)), bytes1(0x00));
//         // (bool out2,) = address(poolManager).staticcall(abi.encodeWithSignature("openToPublic()"));
//         // console.log("out - ",out2);
//         // // assertFalse(out2);
//         vm.stopPrank();

//         vm.startPrank(user);
//         usdc.approve(address(loan), 1e7 * 1e6);
//         loan.investUSDCMapleCash(1e7 * 1e6);
//         assertEq(usdc.balanceOf(user),0);
//         console.log("LP balance", pool.balanceOf(address(loan)));
//         uint256 shares = pool.balanceOf(address(loan));
//         console.log("Shares converted to assets before warp: ", pool.convertToAssets(shares));

//         //time warp 
//         vm.warp(block.timestamp + 100 days);

//         console.log("Shares converted to assets after 100 days: ", pool.convertToAssets(shares));
//         //requesting redeem
//         uint256 escrowShares = loan.requestRedeemUSDCMapleCash(shares);
//          //preview redemption
//         uint256 b = loan.previewRedeemAsset(shares);
//         console.log("Resulting assets: ", b);
//         console.log("Escrow Shares: ", escrowShares);
//         console.log("LP balance after redeem requset", pool.balanceOf(address(loan)));
//         vm.stopPrank();
    
//     }
// }
// // https://rpc.vnet.tenderly.co/devnet/nstbl/584b585c-6c2d-4103-b82c-b6f18c34c2e7