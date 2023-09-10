// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LoanManagerV1 } from "../../contracts/LoanManagerV1.sol";
import { LoanManagerV2 } from "../../contracts/LoanManagerV2.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPoolManager } from "../../contracts/interfaces/maple/IPoolManager.sol";
import { IWithdrawalManager, IWithdrawalManagerStorage } from "../../contracts/interfaces/maple/IWithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/maple/IPool.sol";
import { Utils } from "./Utils.sol";

contract BaseTest is Utils {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public lmProxy;

    // Main contracts
    LoanManagerV1 public lmImp1;
    LoanManagerV2 public lmImp2;

    LoanManagerV1 public loanManager;

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
        lmImp1 = new LoanManagerV1(owner, MAPLE_USDC_CASH_POOL, MAPLE_USDT_CASH_POOL);
        bytes memory data = abi.encodeCall(lmImp1.initialize, (NSTBL_HUB));
        lmProxy = new TransparentUpgradeableProxy(address(lmImp1), owner, data);
        vm.stopPrank();

        loanManager = LoanManagerV1(address(lmProxy));
        lusdc = IERC20(address(loanManager.lUSDC()));
        lusdt = IERC20(address(loanManager.lUSDT()));
        usdc = IERC20(USDC);
        usdt = IERC20(USDT);
        usdcPool = IPool(MAPLE_USDC_CASH_POOL);
        usdtPool = IPool(MAPLE_USDT_CASH_POOL);
        poolManagerUSDC = IPoolManager(MAPLE_POOL_MANAGER_USDC);
        poolManagerUSDT = IPoolManager(MAPLE_POOL_MANAGER_USDT);
        withdrawalManagerUSDC = IWithdrawalManager(WITHDRAWAL_MANAGER_USDC);
        withdrawalManagerUSDT = IWithdrawalManager(WITHDRAWAL_MANAGER_USDT);

        vm.label(address(loanManager), "LoanManager");
        vm.label(address(usdc), "USDC");
        vm.label(address(usdcPool), "USDC Pool");
        vm.label(poolDelegateUSDC, "poolDelegate USDC");
        vm.label(address(poolManagerUSDC), "poolManager USDC");
    }

    // function _setAllowedLender(address _delegate) internal {
    //     bool out;
    //     vm.startPrank(_delegate);
    //     if (_delegate == poolDelegateUSDC) {
    //         poolManagerUSDC.setAllowedLender(address(loanManager), true);
    //         (out,) = address(poolManagerUSDC).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
    //     } else {
    //         poolManagerUSDT.setAllowedLender(address(loanManager), true);
    //         (out,) = address(poolManagerUSDT).staticcall(abi.encodeWithSignature("isValidLender(address)", user));
    //     }
    //     assertTrue(out);
    //     vm.stopPrank();
    // }

    // function _investAssets(address _asset, address _pool, uint256 amount) internal {
    //     erc20_deal(_asset, NSTBL_HUB, amount);

    //     if (_asset == USDC) {
    //         _setAllowedLender(poolDelegateUSDC);
    //     } else {
    //         _setAllowedLender(poolDelegateUSDT);
    //     }

    //     vm.startPrank(NSTBL_HUB);
    //     IERC20(_asset).safeIncreaseAllowance(address(loanManager), amount);

    //     loanManager.deposit(_asset, amount);
    //     vm.stopPrank();
    // }

    // function _getLiquidityCap(address _poolManager) internal view returns (uint256) {
    //     (, bytes memory val) = address(_poolManager).staticcall(abi.encodeWithSignature("liquidityCap()"));
    //     return uint256(bytes32(val));
    // }

    // function _getUpperBoundDeposit(address _pool, address _poolManager) internal returns (uint256) {
    //     uint256 upperBound = _getLiquidityCap(_poolManager);
    //     uint256 totalAssets = IPool(_pool).totalAssets();
    //     return upperBound - totalAssets;
    // }
}
