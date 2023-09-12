// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LoanManagerV1, TokenLP } from "../../contracts/LoanManagerV1.sol";
import { LoanManagerV2 } from "../../contracts/LoanManagerV2.sol";
import { LoanManagerV3 } from "../../contracts/LoanManagerV3.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPoolManager } from "../../contracts/interfaces/maple/IPoolManager.sol";
import { IWithdrawalManager, IWithdrawalManagerStorage } from "../../contracts/interfaces/maple/IWithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/maple/IPool.sol";
import { Utils } from "../helpers/Utils.sol";

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
    LoanManagerV3 public lmImp3;

    LoanManagerV1 public loanManager;
    LoanManagerV2 public loanManager2;
    LoanManagerV3 public loanManager3;

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

    error OwnableUnauthorizedAccount(address);
    error Initialized();
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
        vm.label(address(loanManager), "LoanManager");
    }

    function testProxy() external {
        console.log("Proxy Address: ", address(lmProxy));
        console.log("Implementation Address: ", address(lmImp1));
        console.log("Implementation Version - ", loanManager.getVersion());
    }

    function testConstructorParams() external {
        assertEq(loanManager.usdc(), USDC);
        assertEq(loanManager.usdt(), USDT);
        assertEq(loanManager.admin(), owner);
        assertEq(loanManager.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager.mapleUSDTPool(), MAPLE_USDT_CASH_POOL);
        TokenLP lToken = loanManager.lUSDC();
        console.log(lToken.name());
        console.log(lmImp1.adjustedDecimals());
        console.log(loanManager.adjustedDecimals());
    }

    function testProxyAdmin_fakeOwner() external {
        proxyAdmin = ProxyAdmin(0x8D7716695F608dC7d9C55071F400022B65542687);
        assertEq(proxyAdmin.owner(), owner);

        address fakeOwner = address(1234);
        vm.startPrank(fakeOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, fakeOwner));
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(lmProxy)), address(0), "");
        vm.stopPrank();
    }

    function testProxyAdmin_Initializer() external {
        proxyAdmin = ProxyAdmin(0x8D7716695F608dC7d9C55071F400022B65542687);
        assertEq(proxyAdmin.owner(), owner);

        vm.startPrank(owner);
        bytes memory data = abi.encodeCall(lmImp1.initialize, (NSTBL_HUB));
        vm.expectRevert(abi.encodeWithSelector(Initialized.selector));
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(lmProxy)), address(lmImp1), data);
        vm.stopPrank();

    }

    function testProxyAdmin_Same_Implementation() external {
        proxyAdmin = ProxyAdmin(0x8D7716695F608dC7d9C55071F400022B65542687);
        vm.startPrank(owner);
        //upgrading to the same implementation with empty initializer data
        //Expecting no changes in storage of the proxy contract
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(lmProxy)), address(lmImp1), "");
        vm.stopPrank();

        assertEq(loanManager.usdc(), USDC);
        assertEq(loanManager.usdt(), USDT);
        assertEq(loanManager.admin(), owner);
        assertEq(loanManager.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager.mapleUSDTPool(), MAPLE_USDT_CASH_POOL);

        assertEq(loanManager.adjustedDecimals(), 12);
        assertEq(loanManager.nstblHub(), NSTBL_HUB);
        TokenLP lToken = loanManager.lUSDC();
        assertEq(lToken.name(), "Loan Manager USDC");
        assertEq(lToken.totalSupply(), 0);

        lToken = loanManager.lUSDT();
        assertEq(lToken.name(), "Loan Manager USDT");
        assertEq(lToken.totalSupply(), 0);
    }

    function testProxyAdmin_New_Implementation_noConstructor() external {
        lmImp2 = new LoanManagerV2();

        proxyAdmin = ProxyAdmin(0x8D7716695F608dC7d9C55071F400022B65542687);
        vm.startPrank(owner);

        //upgrading without any changes to the code and storage
        //there's no constructor and initialize function in the V2 implementation
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(lmProxy)), address(lmImp2), "");
        vm.stopPrank();

        loanManager2 = LoanManagerV2(address(lmProxy));

        console.log("Proxy Address: ", address(lmProxy));
        console.log("New Implementation Address: ", address(lmImp2));
        console.log("Implementation Version - ", loanManager2.getVersion());
        assertEq(loanManager2.getVersion(), 2);

        assertEq(loanManager2.usdc(), USDC);
        assertEq(loanManager2.usdt(), USDT);
        assertEq(loanManager2.admin(), address(0));
        assertEq(loanManager2.mapleUSDCPool(), address(0));
        assertEq(loanManager2.mapleUSDTPool(), address(0));

        assertEq(loanManager2.adjustedDecimals(), 0);
        assertEq(loanManager2.nstblHub(), NSTBL_HUB);
        TokenLP lToken = loanManager2.lUSDC();
        assertEq(address(lToken), address(0));

        lToken = loanManager2.lUSDT();
        assertEq(address(lToken), address(0));

        console.log("Locked Value - - ", loanManager2.getLocked());
    }

    function testProxyAdmin_New_Implementation_withConstructor() external {

        
        lmImp3 = new LoanManagerV3(owner, MAPLE_USDC_CASH_POOL, MAPLE_USDT_CASH_POOL, address(loanManager.lUSDC()), address(loanManager.lUSDT()));

        proxyAdmin = ProxyAdmin(0x8D7716695F608dC7d9C55071F400022B65542687);
        vm.startPrank(owner);
        bytes memory data = abi.encodeCall(lmImp3.initialize, (100, 50, 20));
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(lmProxy)), address(lmImp3), data);
        vm.stopPrank();

        loanManager3 = LoanManagerV3(address(lmProxy));

        console.log("Proxy Address: ", address(lmProxy));
        console.log("New Implementation Address: ", address(lmImp3));
        console.log("Implementation Version - ", loanManager3.getVersion());
        assertEq(loanManager3.getVersion(), 3);

        assertEq(loanManager3.usdc(), USDC);
        assertEq(loanManager3.usdt(), USDT);
        assertEq(loanManager3.admin(), owner);
        assertEq(loanManager3.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager3.mapleUSDTPool(), MAPLE_USDT_CASH_POOL);

        assertEq(loanManager3.adjustedDecimals(), 12);
        assertEq(loanManager3.nstblHub(), NSTBL_HUB);
        TokenLP lToken = loanManager3.lUSDC();
        assertEq(lToken.name(), "Loan Manager USDC");
        assertEq(lToken.totalSupply(), 0);

        lToken = loanManager3.lUSDT();
        assertEq(lToken.name(), "Loan Manager USDT");
        assertEq(lToken.totalSupply(), 0);

        assertEq(loanManager3.newVal(), 100);
        assertEq(loanManager3.newVal2(), 50);
        assertEq(loanManager3.newVal3(), 20);
        assertEq(loanManager3.newVal4(), 150);
        console.log("Locked Val - -", loanManager3.getLocked());

    }


}
