// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { TokenLP } from "../../contracts/TokenLP.sol";

contract TestToken is Test {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    // Main contract
    TokenLP public token;

    // EOA addresses
    address public LoanManager = vm.addr(1);
    address public admin = vm.addr(2);

    // Constants
    string public name = "Nealthy loan token USDC";
    string public symbol = "lUSDC";

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.prank(admin);
        token = new TokenLP(name, symbol, admin);
        vm.label(address(token), "Token");
        vm.label(LoanManager, "LoanManager");

        vm.prank(admin);
        token.setLoanManager(LoanManager);
    }

    function test_name() public {
        assertEq(token.name(), name);
    }

    function test_symbol() public {
        assertEq(token.symbol(), symbol);
    }

    function test_loanManager() public {
        assertEq(token.loanManager(), LoanManager);
    }

    function test_setLoanManager_fuzz(address newLoanManager) public {
        // Test that only admin can set the new LoanManager
        vm.expectRevert("Token: Admin unAuth");
        token.setLoanManager(newLoanManager);

        // Test that admin can set the new LoanManager
        vm.prank(admin);
        token.setLoanManager(newLoanManager);
        assertEq(token.loanManager(), newLoanManager, "LoanManager set successfully");
    }

    function test_setAdmin_fuzz(address newAdmin) public {
        // Test that only admin can set the new admin
        vm.expectRevert("Token: Admin unAuth");
        token.setAdmin(newAdmin);

        // Test that admin can set the new admin
        vm.prank(admin);
        token.setAdmin(newAdmin);
        assertEq(token.admin(), newAdmin, "Admin set successfully");
    }

    function test_mint_fuzz(uint256 amount) public {
        // Test that only admin can set the new LoanManager
        vm.expectRevert("Token: LoanManager unAuth");
        token.mint(LoanManager, amount);

        vm.prank(LoanManager);
        token.mint(LoanManager, amount);
        assertEq(token.balanceOf(LoanManager), amount);
    }

    function test_burn_fuzz(uint256 mint_amount, uint256 burn_amount) public {
        vm.assume(mint_amount >= burn_amount);

        vm.startPrank(LoanManager);
        token.mint(LoanManager, mint_amount);
        token.burn(LoanManager, burn_amount);
        vm.stopPrank();

        assertEq(token.balanceOf(LoanManager), mint_amount - burn_amount);
    }

    function test_burn_accessControl() public {
        // Test that only admin can set the new LoanManager
        vm.expectRevert("Token: LoanManager unAuth");
        token.burn(LoanManager, 100);
    }
}
