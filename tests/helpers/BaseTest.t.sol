// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPoolManager } from "../../contracts/interfaces/IPoolManager.sol";
import { IWithdrawalManager } from "../../contracts/interfaces/IWithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";
import { Utils } from "./Utils.sol";

contract BaseTest is Utils {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    // Main contracts
    LoanManager public loanManager;
    // Token public token;
    IERC20 public usdc;
    IERC20 public usdt;

    IERC20 public lusdc;
    IERC20 public lusdt;

    IPool public pool;
    IPoolManager public poolManager;
    IWithdrawalManager public withdrawalManager;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.startPrank(owner);
        // token = new Token(name, symbol);
        loanManager = new LoanManager(
            NSTBL_HUB,
            MAPLE_USDC_CASH_POOL,
            USDC,
            owner
        );
        vm.stopPrank();
        lusdc = IERC20(address(loanManager.lUSDC()));
        usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        pool = IPool(0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92);
        poolManager = IPoolManager(0x219654A61a0BC394055652986BE403fa14405Bb8);
        withdrawalManager = IWithdrawalManager(0x1146691782c089bCF0B19aCb8620943a35eebD12);

        vm.label(address(loanManager), "LoanManager");
        vm.label(address(usdc), "USDC");
        vm.label(address(pool), "Pool");
        vm.label(poolDelegate, "poolDelegate");
        vm.label(address(poolManager), "poolManager");
    }

    function _setAllowedLender() internal {
        vm.startPrank(poolDelegate);
        poolManager.setAllowedLender(address(loanManager), true);
        (bool out,) = address(poolManager).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        assertTrue(out);
        vm.stopPrank();
    }
}
