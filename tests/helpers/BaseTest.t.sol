// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPoolManager } from "../../contracts/interfaces/IPoolManager.sol";
import { IWithdrawalManager } from "../../contracts/interfaces/IWithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";
import { Utils } from "./Utils.sol";

contract BaseTest is Utils {
    using SafeERC20 for IERC20;
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

    IPool public usdcPool;
    IPool public usdtPool;
    IPoolManager public poolManagerUSDC;
    IWithdrawalManager public withdrawalManagerUSDC;
    IPoolManager public poolManagerUSDT;
    IWithdrawalManager public withdrawalManagerUSDT;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.startPrank(owner);
        // token = new Token(name, symbol);
        loanManager = new LoanManager(
            NSTBL_HUB,
            owner,
            MAPLE_USDC_CASH_POOL,
            MAPLE_USDT_CASH_POOL
        );
        vm.stopPrank();
        lusdc = IERC20(address(loanManager.lUSDC()));
        lusdt = IERC20(address(loanManager.lUSDT()));
        usdc = IERC20(USDC);
        usdt = IERC20(USDT);
        usdcPool = IPool(MAPLE_USDC_CASH_POOL);
        usdtPool = IPool(MAPLE_USDT_CASH_POOL);
        poolManagerUSDC = IPoolManager(0x219654A61a0BC394055652986BE403fa14405Bb8);
        poolManagerUSDT = IPoolManager(0xE76b219f83E887E2503E14c343Bb7E0B62A7Af5d);
        withdrawalManagerUSDC = IWithdrawalManager(0x1146691782c089bCF0B19aCb8620943a35eebD12);
        withdrawalManagerUSDT = IWithdrawalManager(0xF0A66F70064aD3198Abb35AAE26B1eeeaEa62C4B);

        vm.label(address(loanManager), "LoanManager");
        vm.label(address(usdc), "USDC");
        vm.label(address(usdcPool), "USDC Pool");
        vm.label(poolDelegateUSDC, "poolDelegate USDC");
        vm.label(address(poolManagerUSDC), "poolManager USDC");
    }

    function _setAllowedLender(address _delegate) internal {
        bool out;
        vm.startPrank(_delegate);
        if (_delegate == poolDelegateUSDC) {
            poolManagerUSDC.setAllowedLender(address(loanManager), true);
            (out,) = address(poolManagerUSDC).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        } else {
            poolManagerUSDT.setAllowedLender(address(loanManager), true);
            (out,) = address(poolManagerUSDT).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
        }
        // assertTrue(out);
        vm.stopPrank();
    }

    function _investAssets(address _asset, address _pool) internal {
        erc20_deal(_asset, NSTBL_HUB, 1e7 * 1e6);

        if(_asset == USDC)
            _setAllowedLender(poolDelegateUSDC);
        else
            _setAllowedLender(poolDelegateUSDT);

        vm.startPrank(NSTBL_HUB);
        IERC20(_asset).safeIncreaseAllowance(address(loanManager), 1e7 * 1e6);

        uint256 sharesToReceive = IPool(_pool).previewDeposit(1e7 * 1e6);
        loanManager.deposit(_asset, 1e7 * 1e6);
        assertEq(IERC20(_asset).balanceOf(user), 0);
        assertEq(IPool(_pool).balanceOf(address(loanManager)), sharesToReceive);
        vm.stopPrank();
    }
}
