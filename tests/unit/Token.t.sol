// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { TokenLP } from "../../contracts/TokenLP.sol";
import { ACLManager } from "@nstbl-acl-manager/contracts/ACLManager.sol";

contract TestToken is Test {
    /*//////////////////////////////////////////////////////////////
    State
    //////////////////////////////////////////////////////////////*/

    // Main contract
    ACLManager public aclManager;
    TokenLP public token;

    // EOA addresses
    address public LoanManager = vm.addr(1);
    address public admin = vm.addr(2);

    // Constants
    string public name = "Nealthy loan token USDC";
    string public symbol = "lUSDC";

    /*//////////////////////////////////////////////////////////////
    Setup
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(admin);
        aclManager = new ACLManager();
        token = new TokenLP(name, symbol, address(aclManager));
        vm.stopPrank();
        vm.prank(admin);
        token.setLoanManager(LoanManager);

        vm.label(address(token), "Token");
        vm.label(LoanManager, "LoanManager");
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
        vm.assume(newLoanManager != address(0));
        // Test that only admin can set the new LoanManager
        vm.expectRevert("Token: Admin unAuth");
        token.setLoanManager(newLoanManager);

        // Test new address cannot be zero
        vm.expectRevert("Token: invalid Address");
        vm.prank(admin);
        token.setLoanManager(address(0));

        // Test that admin can set the new LoanManager
        vm.prank(admin);
        token.setLoanManager(newLoanManager);
        assertEq(token.loanManager(), newLoanManager, "LoanManager set successfully");
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
