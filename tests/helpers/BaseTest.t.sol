// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
// import { LoanManagerV2 } from "../../contracts/upgradeable/test/LoanManagerV2.sol";
import { ACLManager } from "@nstbl-acl-manager/contracts/ACLManager.sol";
import { ProxyAdmin } from "../../contracts/upgradeable/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "../../contracts/upgradeable/TransparentUpgradeableProxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IPoolManager } from "../../contracts/interfaces/maple/IPoolManager.sol";
import { IPoolPermissionManager } from "../../contracts/interfaces/maple/IPoolPermissionManager.sol";
import { IWithdrawalManager, IWithdrawalManagerStorage } from "../../contracts/interfaces/maple/IWithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/maple/IPool.sol";
import { Utils } from "./Utils.sol";

contract BaseTest is Utils {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
    State
    //////////////////////////////////////////////////////////////*/

    // Main contracts
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public loanManagerProxy;

    ACLManager public aclManager;
    LoanManager public lmImpl1;
    // LoanManagerV2 public lmImpl2;

    LoanManager public loanManager;
    // Token public token;
    IERC20 public usdc;

    IERC20 public lusdc;

    IPool public usdcPool;
    IPoolManager public poolManagerUSDC;
    IPoolPermissionManager public poolPermissionManagerUSDC;
    IWithdrawalManager public withdrawalManagerUSDC;
    uint256 mainnetFork;

    /*//////////////////////////////////////////////////////////////
    Setup
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        mainnetFork = vm.createFork(vm.envString("DEV_RPC_URL"));
        vm.selectFork(mainnetFork);
        vm.startPrank(owner);

        aclManager = new ACLManager();
        aclManager.setAuthorizedCallerLoanManager(NSTBL_HUB, true);
        require(
            NSTBL_HUB != address(0) && owner != address(0) && MAPLE_USDC_CASH_POOL != address(0)
                && MAPLE_POOL_MANAGER_USDC != address(0) && WITHDRAWAL_MANAGER_USDC != address(0) && USDC != address(0)
        );
        proxyAdmin = new ProxyAdmin(owner);
        lmImpl1 = new LoanManager();
        // lmImpl2 = new LoanManagerV2();
        bytes memory data = abi.encodeCall(lmImpl1.initialize, (address(aclManager), MAPLE_USDC_CASH_POOL));
        loanManagerProxy = new TransparentUpgradeableProxy(address(lmImpl1), address(proxyAdmin), data);
        loanManager = LoanManager(address(loanManagerProxy));
        loanManager.updateNSTBLHUB(NSTBL_HUB);
        vm.stopPrank();

        lusdc = IERC20(address(loanManager.lUSDC()));
        usdc = IERC20(USDC);
        usdcPool = IPool(MAPLE_USDC_CASH_POOL);
        poolManagerUSDC = IPoolManager(MAPLE_POOL_MANAGER_USDC);
        poolPermissionManagerUSDC = IPoolPermissionManager(MAPLE_POOL_PERMISSION_MANAGER);
        withdrawalManagerUSDC = IWithdrawalManager(WITHDRAWAL_MANAGER_USDC);

        vm.label(address(loanManager), "LoanManager");
        vm.label(address(usdc), "USDC");
        vm.label(address(usdcPool), "USDC Pool");
        vm.label(poolDelegateUSDC, "poolDelegate USDC");
        vm.label(address(poolManagerUSDC), "poolManager USDC");

        vm.prank(poolDelegateUSDC);
        withdrawalManagerUSDC.setManualWithdrawal(address(loanManager), true);
    }

    function _setAllowedLender(address _delegate) internal {
        bool out;
        vm.startPrank(_delegate);

        address[] memory lenders = new address[](1);
        bool[] memory val = new bool[](1);
        lenders[0] = address(loanManager);
        val[0] = true;
        poolPermissionManagerUSDC.setLenderAllowlist(MAPLE_POOL_MANAGER_USDC, lenders, val);
        // (out,) = address(poolManagerUSDC).staticcall(abi.encodeWithSignature("isValidLender(address)", user));

        // assertTrue(out);
        vm.stopPrank();
    }

    function _investAssets(address _asset, uint256 amount) internal {
        erc20_deal(NSTBL_HUB, amount);

        if (_asset == USDC) {
            _setAllowedLender(poolDelegateUSDC);
        }

        vm.startPrank(NSTBL_HUB);
        IERC20(_asset).safeIncreaseAllowance(address(loanManager), amount);

        loanManager.deposit(amount);
        vm.stopPrank();
    }

    function _getLiquidityCap(address _poolManager) internal view returns (uint256) {
        (, bytes memory val) = address(_poolManager).staticcall(abi.encodeWithSignature("liquidityCap()"));
        return uint256(bytes32(val));
    }

    function _getUpperBoundDeposit(address _pool, address _poolManager) internal view returns (uint256) {
        uint256 upperBound = _getLiquidityCap(_poolManager);
        uint256 totalAssets = IPool(_pool).totalAssets();
        return upperBound - totalAssets;
    }
}
