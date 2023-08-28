// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../helpers/BaseTest.t.sol";

contract TestDeposit is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testInvest() public {
        vm.prank(owner);
        loanManager.setAuthorizedCaller(user);

        erc20_deal(USDC, user, 1e7 * 1e6);

        _setAllowedLender();

        vm.startPrank(user);
        usdc.approve(address(loanManager), 1e7 * 1e6);
        
        uint256 sharesToReceive = pool.previewDeposit(1e7 * 1e6);

        console.log("Deposit Preview: ", pool.previewDeposit(1e7 * 1e6));
        loanManager.investUSDCMapleCash(1e7 * 1e6);
        assertEq(usdc.balanceOf(user), 0);

        console.log("Maple USDC shares balance: ", pool.balanceOf(address(loanManager)));
        // console.log("LM lUSDC minted to nstblHub: ", lusdc.balanceOf(0x749f88e87EaEb030E478164cFd3681E27d0bcB42));
        console.log("LM lUSDC minted to nstblHub: ", lusdc.balanceOf(address(loanManager)));
        console.log(lusdc.totalSupply());
        vm.stopPrank();
    }

}
