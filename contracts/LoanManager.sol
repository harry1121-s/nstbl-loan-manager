// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPool, IERC20Helper, IWithdrawalManagerStorage, IWithdrawalManager, LMTokenLP, LoanManagerStorage } from "./LoanManagerStorage.sol";

contract LoanManager is LoanManagerStorage {
    using SafeERC20 for IERC20Helper;

    uint256 private _locked = 1;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(msg.sender == nstblHub, "Loan Manager: unAuth Hub");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "LM: unAuth Admin");
        _;
    }

    modifier validInput(address _asset, uint256 _amount) {
        require(_asset != address(0), "LM: Invalid Target address");
        require(_amount > 0, "LM: Insufficient amount");
        _;
    }

    modifier validAsset(address _asset) {
        require(_asset != address(0), "LM: Invalid Target address");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "P:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _nstblHub, address _admin, address _mapleUSDCPool, address _mapleUSDTPool) {
        nstblHub = _nstblHub;
        admin = _admin;
        mapleUSDCPool = _mapleUSDCPool;
        mapleUSDTPool = _mapleUSDTPool;
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        lUSDC = new LMTokenLP("Loan Manager USDC", "lUSDC", _admin);
        lUSDT = new LMTokenLP("Loan Manager USDT", "lUSDT", _admin);
        adjustedDecimals = lUSDC.decimals() - IPool(mapleUSDCPool).decimals();
    }

    /*//////////////////////////////////////////////////////////////
                            LP Functions
    //////////////////////////////////////////////////////////////*/

    function deposit(address _asset, uint256 _amount)
        public
        authorizedCaller
        nonReentrant
        validAsset(_asset)
    {
        if (_asset == usdc) {
            _depositMapleCash(_amount, usdc, mapleUSDCPool, address(lUSDC), MAPLE_POOL_MANAGER_USDC);
        } else if (_asset == usdt) {
            _depositMapleCash(_amount, usdt, mapleUSDTPool, address(lUSDT), MAPLE_POOL_MANAGER_USDT);
        }
    }

    function requestRedeem(address _asset, uint256 _lpTokens)
        public
        authorizedCaller
        nonReentrant
        validInput(_asset, _lpTokens)
    {
        if (_asset == usdc) {
            _requestRedeemMapleCash(_lpTokens, usdc, mapleUSDCPool, address(lUSDC));
        } else if (_asset == usdt) {
            _requestRedeemMapleCash(_lpTokens, usdt, mapleUSDTPool, address(lUSDT));
        }
    }
    // @TODO: add a check for redemptionRequested   `
    function redeem(address _asset) public authorizedCaller nonReentrant validAsset(_asset) {
        // require(_asset != address(0), "LM: Invalid Target address");
        if (_asset == usdc) {
            _redeemMapleCash(usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
        } else if (_asset == usdt) {
            _redeemMapleCash(usdt, mapleUSDTPool, address(lUSDT), MAPLE_WITHDRAWAL_MANAGER_USDT);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           LM Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _depositMapleCash(uint256 _amount, address _asset, address _pool, address _lpToken, address _poolManager)
        internal
    {
        require(isValidDepositAmount(_amount, _pool, _poolManager), "LM: Invalid amount");
        uint256 lpTokens;
        uint256 sharesReceived;
        IERC20Helper(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Helper(_asset).safeIncreaseAllowance(_pool, _amount);

        totalAssetsReceived[_asset] += _amount;
        sharesReceived = IPool(_pool).previewDeposit(_amount);
        totalSharesReceived[_asset] += sharesReceived;
        IPool(_pool).deposit(_amount, address(this));
        lpTokens = sharesReceived * 10 ** adjustedDecimals;
        totalLPTokensMinted[address(lUSDC)] += lpTokens;
        IERC20Helper(_lpToken).mint(nstblHub, lpTokens);
        emit Deposit(_asset, _amount, lpTokens, sharesReceived);
    }

    function _requestRedeemMapleCash(uint256 _lpTokens, address _asset, address _pool, address _lpToken) internal {
        require(!awaitingRedemption[_asset], "LM: Redemption Pending");
        require(IPool(_pool).balanceOf(address(this)) >= _lpTokens / 10 ** adjustedDecimals, "LM: Insufficient Shares");
        escrowedMapleShares[_lpToken] = IPool(_pool).requestRedeem(_lpTokens / 10 ** adjustedDecimals, address(this));
        awaitingRedemption[_asset] = true;
        emit RequestRedeem(_asset, _lpTokens, escrowedMapleShares[_lpToken]);
    }

    function _redeemMapleCash(address _asset, address _pool, address _lpToken, address _withdrawManager) internal {
        uint256 _shares = escrowedMapleShares[_lpToken];
        uint256 stablesRedeemed = IPool(_pool).redeem(_shares, nstblHub, address(this));
        assetsRedeemed[_asset] += stablesRedeemed;
        escrowedMapleShares[_lpToken] = IWithdrawalManagerStorage(_withdrawManager).lockedShares(address(this));
        IERC20Helper(_lpToken).burn(nstblHub, (_shares-escrowedMapleShares[_lpToken]) * 10**adjustedDecimals);
        if(escrowedMapleShares[_lpToken] == 0)
            awaitingRedemption[_asset] = false;
        emit Redeem(_asset, _shares, assetsRedeemed[_asset]);
    }

    /*//////////////////////////////////////////////////////////////
                           LM Getter Functions
    //////////////////////////////////////////////////////////////*/

    function getLpTokensPendingRedemption(address _lpToken)public view returns(uint256) {
        return escrowedMapleShares[_lpToken] * 10**adjustedDecimals;
    }

    function getAssets(address _asset, uint256 _lpTokens) public validInput(_asset, _lpTokens) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToAssets(_lpTokens / 10 ** adjustedDecimals);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToAssets(_lpTokens / 10 ** adjustedDecimals);
        }
    }

    function getAssetsWithUnrealisedLosses(address _asset, uint256 _lpTokens)
        public
        validInput(_asset, _lpTokens)
        returns (uint256)
    {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToExitAssets(_lpTokens / 10 ** adjustedDecimals);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToExitAssets(_lpTokens / 10 ** adjustedDecimals);
        }
    }

    function getShares(address _asset, uint256 _amount) public validInput(_asset, _amount) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToShares(_amount);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToShares(_amount);
        }
    }

    function getExitShares(address _asset, uint256 _amount) public validInput(_asset, _amount) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToExitShares(_amount);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToExitShares(_amount);
        }
    }

    function getUnrealizedLossesMaple(address _asset) public validAsset(_asset) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).unrealizedLosses();
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).unrealizedLosses();
        }
    }

    function getTotalAssetsMaple(address _asset) public validAsset(_asset) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).totalAssets();
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).totalAssets();
        }
    }

    function previewRedeem(address _asset, uint256 _shares) public returns (uint256) {
        uint256 assetValue;
        if (_asset == usdc) {
            assetValue = IPool(mapleUSDCPool).previewRedeem(_shares / 10 ** 12);
        } else if (_asset == usdt) {
            assetValue = IPool(mapleUSDTPool).previewRedeem(_shares / 10 ** 12);
        }
        return assetValue;
    }

    function previewDepositAssets(address _asset, uint256 _amount) public returns (uint256) {
        uint256 assetValue;
        if (_asset == usdc) {
            assetValue = IPool(mapleUSDCPool).previewDeposit(_amount);
            // (, bytes memory val) = mapleUSDCPool.call(abi.encodeWithSignature(("previewDeposit(uint256)"), _lpToken / 10**adjustedDecimals));
            // assetValue = uint256(bytes32(val));
        } else if (_asset == usdt) {
            assetValue = IPool(mapleUSDTPool).previewDeposit(_amount);
            // (, bytes memory val) = mapleUSDTPool.call(abi.encodeWithSignature(("previewDeposit(uint256)"), _lpToken / 10**adjustedDecimals));
            // assetValue = uint256(bytes32(val));
        }
        return assetValue;
    }

    function isValidDepositAmount(uint256 _amount, address _pool, address _poolManager) public returns (bool) {
        (, bytes memory val) = address(_poolManager).staticcall(abi.encodeWithSignature("liquidityCap()"));
        uint256 upperBound = uint256(bytes32(val));
        uint256 totalAssets = IPool(_pool).totalAssets();
        uint256 shares = IPool(_pool).previewDeposit(_amount);
        return (shares > 0) && (_amount < (upperBound - totalAssets)) ? true : false;
    }

    /*//////////////////////////////////////////////////////////////
                           LM Admin Functions
    //////////////////////////////////////////////////////////////*/

    function setAuthorizedCaller(address _caller) public onlyAdmin {
        nstblHub = _caller;
    }
}
