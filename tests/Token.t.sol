// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import { Test, console } from "forge-std/Test.sol";
// import { Token } from "../contracts/Token.sol";

// contract TestToken is Test {
//     Token public token;
//     address public LoanManager = vm.addr(1);
//     address public admin = vm.addr(2);
//     string public name = "Nealthy loan token USDC";
//     string public symbol = "lUSDC";

//     function setUp() public {
//         vm.prank(admin);
//         token = new Token(name, symbol);
//         vm.label(address(token), "Token");
//         vm.label(LoanManager, "LoanManager");
//     }

//     function testMint() public {
//         vm.prank(LoanManager);
//         token.mint(LoanManager, 100);
//         assertEq(token.balanceOf(LoanManager), 100);
//     }

//     function testBurn() public {
//         vm.startPrank(LoanManager);
//         token.mint(LoanManager, 100);
//         token.burn(LoanManager, 50);
//         vm.stopPrank();
//         assertEq(token.balanceOf(LoanManager), 50);
//     }

//     function testName() public {
//         assertEq(token.name(), name);
//     }

//     function testSymbol() public {
//         assertEq(token.symbol(), symbol);
//     }

//     function testLoanManager() public {
//         assertEq(token.loanManager(), LoanManager);
//     }

//     function testLoanManagerSet() public {
//         vm.prank(admin);
//         token.setLoanManager(admin);
//         assertEq(token.loanManager(), admin);
//     }

//     function testAdminSet() public {
//         vm.prank(admin);
//         token.setAdmin(LoanManager);
//         assertEq(token.admin(), LoanManager);
//     }
// }
