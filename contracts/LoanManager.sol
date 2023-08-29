// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { LoanManagerStorage, IPool, IERC20, LMTokenLP } from "./LoanManagerStorage.sol";
import { console } from "forge-std/Test.sol";

contract LoanManager is Ownable, LoanManagerStorage {
    using SafeERC20 for IERC20;

    uint256 private _locked = 1;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(msg.sender == nstblHub, "Loan Manager: unAuth");
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

    constructor(
        address _nstblHub,
        address _mapleUSDCPool,
        address _mapleUSDTPool,
        address _usdc,
        address _usdt,
        address _admin
    ) Ownable(msg.sender) {
        nstblHub = _nstblHub;
        mapleUSDCPool = IPool(_mapleUSDCPool);
        mapleUSDTPool = IPool(_mapleUSDTPool);
        usdc = IERC20(_usdc);
        usdt = IERC20(_usdt);
        lUSDC = new LMTokenLP("Loan Manager USDC", "lUSDC", _admin);
        lUSDT = new LMTokenLP("Loan Manager USDT", "lUSDT", _admin);
        adjustedDecimals = lUSDC.decimals() - mapleUSDCPool.decimals();
    }

    function deposit(address _asset, uint256 _amount)
        public
        authorizedCaller
        nonReentrant
        validInput(_asset, _amount)
    {
        // require(_asset != address(0), "LM: Invalid Target address");
        // require( _amount > 0, "LM: Insufficient amount");

        if (_asset == address(usdc)) {
            _investUSDCMapleCash(_amount);
        } else if (_asset == address(usdt)) {
            _investUSDTMapleCash(_amount);
        }
    }

    function _investUSDCMapleCash(uint256 _amount) internal {
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        usdcDeposited += _amount;
        usdc.approve(address(mapleUSDCPool), _amount);
        usdcSharesReceived = mapleUSDCPool.previewDeposit(_amount);
        mapleUSDCPool.deposit(_amount, address(this));
        totalUSDCSharesReceived += usdcSharesReceived;
        uint256 lpTokens = usdcSharesReceived * 10 ** adjustedDecimals;
        lUSDC.mint(nstblHub, lpTokens);
        emit Deposit(address(usdc), _amount, lpTokens, usdcSharesReceived);
    }

    function _investUSDTMapleCash(uint256 _amount) internal {
        usdt.safeTransferFrom(msg.sender, address(this), _amount);
        usdtDeposited += _amount;
        usdt.safeIncreaseAllowance(address(mapleUSDTPool), _amount);
        usdtSharesReceived = mapleUSDTPool.previewDeposit(_amount);
        mapleUSDTPool.deposit(_amount, address(this));
        totalUSDTSharesReceived += usdtSharesReceived;
        uint256 lpTokens = usdtSharesReceived * 10 ** adjustedDecimals;
        lUSDT.mint(nstblHub, lpTokens);
        emit Deposit(address(usdt), _amount, lpTokens, usdtSharesReceived);
    }

    function requestRedeem(address _asset, uint256 _lmTokens)
        public
        authorizedCaller
        nonReentrant
        validInput(_asset, _lmTokens)
    {
        // require(_asset != address(0), "LM: Invalid Target address");
        // require( _lmTokens > 0, "LM: Insufficient amount");

        if (_asset == address(usdc)) {
            _requestRedeemUSDCMapleCash(_lmTokens);
        } else if (_asset == address(usdt)) {
            _requestRedeemUSDTMapleCash(_lmTokens);
        }
    }

    function _requestRedeemUSDCMapleCash(uint256 _lmTokens) internal {
        require(!awaitingUSDCRedemption, "LM: USDC Redemption Pending");
        require(mapleUSDCPool.balanceOf(address(this)) >= _lmTokens / 10 ** adjustedDecimals, "Insufficient amount");
        lusdcRequestedForRedeem = _lmTokens;
        escrowedMapleUSDCShares = mapleUSDCPool.requestRedeem(_lmTokens / 10 ** adjustedDecimals, address(this));
        lUSDC.transferFrom(msg.sender, address(this), _lmTokens);
        awaitingUSDCRedemption = true;
        emit RequestRedeem(address(usdc), _lmTokens, escrowedMapleUSDCShares);
    }

    function _requestRedeemUSDTMapleCash(uint256 _lmTokens) internal {
        require(!awaitingUSDTRedemption, "LM: USDT Redemption Pending");
        require(mapleUSDTPool.balanceOf(address(this)) >= _lmTokens / 10 ** adjustedDecimals, "Insufficient amount");
        lusdtRequestedForRedeem = _lmTokens;
        escrowedMapleUSDTShares = mapleUSDTPool.requestRedeem(_lmTokens / 10 ** adjustedDecimals, address(this));
        lUSDT.transferFrom(msg.sender, address(this), _lmTokens);
        awaitingUSDTRedemption = true;
        emit RequestRedeem(address(usdt), _lmTokens, escrowedMapleUSDTShares);
    }

    function redeem(address _asset) public authorizedCaller nonReentrant validAsset(_asset){
        // require(_asset != address(0), "LM: Invalid Target address");
        if (_asset == address(usdc)) {
            _redeemUSDC();
        } else if (_asset == address(usdt)) {
            _redeemUSDT();
        }
    }

    function _redeemUSDC() internal {
        uint256 _shares = lusdcRequestedForRedeem / 10 ** adjustedDecimals;
        usdcRedeemed = mapleUSDCPool.redeem(_shares, nstblHub, address(this));
        totalUsdcRedeemed += usdcRedeemed;
        lUSDC.burn(address(this), lusdcRequestedForRedeem);
        lusdcRequestedForRedeem = 0;
        escrowedMapleUSDCShares = 0;
        awaitingUSDCRedemption = false;
        emit Redeem(address(usdc), _shares, usdcRedeemed);
    }

    function _redeemUSDT() internal {
        uint256 _shares = lusdtRequestedForRedeem / 10 ** adjustedDecimals;
        usdtRedeemed = mapleUSDTPool.redeem(_shares, nstblHub, address(this));
        totalUsdtRedeemed += usdtRedeemed;
        lUSDT.burn(address(this), lusdtRequestedForRedeem);
        lusdtRequestedForRedeem = 0;
        escrowedMapleUSDTShares = 0;
        awaitingUSDTRedemption = false;
        emit Redeem(address(usdt), _shares, usdcRedeemed);

    }

    function depositPreview() public returns (uint256) { }

    function getAssets(address _asset, uint256 _lmTokens) public validInput(_asset, _lmTokens) returns (uint256) {
        // require(_asset != address(0), "LM: Invalid Target address");
        // require( _lmTokens > 0, "LM: Insufficient amount");
        if (_asset == address(usdc)) {
            return mapleUSDCPool.convertToAssets(_lmTokens / 10 ** adjustedDecimals);
        } else if (_asset == address(usdt)) {
            return mapleUSDTPool.convertToAssets(_lmTokens / 10 ** adjustedDecimals);
        }
    }

    function getAssetsWithUnrealisedLosses(address _asset, uint256 _lmTokens)
        public
        validInput(_asset, _lmTokens)
        returns (uint256)
    {
        // require(_asset != address(0), "LM: Invalid Target address");
        // require( _lmTokens > 0, "LM: Insufficient amount");
        if (_asset == address(usdc)) {
            return mapleUSDCPool.convertToExitAssets(_lmTokens / 10 ** adjustedDecimals);
        } else if (_asset == address(usdt)) {
            return mapleUSDTPool.convertToExitAssets(_lmTokens / 10 ** adjustedDecimals);
        }
    }

    function getShares(address _asset, uint256 _amount) public validInput(_asset, _amount) returns (uint256) {
        // require(_asset != address(0), "LM: Invalid Target address");
        // require( _amount > 0, "LM: Insufficient amount");
        if (_asset == address(usdc)) {
            return mapleUSDCPool.convertToShares(_amount / 10 ** adjustedDecimals);
        } else if (_asset == address(usdt)) {
            return mapleUSDTPool.convertToShares(_amount / 10 ** adjustedDecimals);
        }
    }

    function getExitShares(address _asset, uint256 _amount) public validInput(_asset, _amount) returns (uint256) {
        // require(_asset != address(0), "LM: Invalid Target address");
        // require( _amount > 0, "LM: Insufficient amount");
        if (_asset == address(usdc)) {
            return mapleUSDCPool.convertToExitShares(_amount / 10 ** adjustedDecimals);
        } else if (_asset == address(usdt)) {
            return mapleUSDTPool.convertToExitShares(_amount / 10 ** adjustedDecimals);
        }
    }

    function getUnrealizedLosses(address _asset) public validAsset(_asset) returns (uint256) {
        // require(_asset != address(0), "LM: Invalid Target address");
        if (_asset == address(usdc)) {
            return mapleUSDCPool.unrealizedLosses();
        } else if (_asset == address(usdt)) {
            return mapleUSDTPool.unrealizedLosses();
        }
    }

    function getTotalAssets(address _asset) public validAsset(_asset) returns (uint256) {
        // require(_asset != address(0), "LM: Invalid Target address");
        if (_asset == address(usdc)) {
            return mapleUSDCPool.totalAssets();
        } else if (_asset == address(usdt)) {
            return mapleUSDTPool.totalAssets();
        }
    }

    // function investUSDTMapleCash(uint256 _assets)public authorizedCaller{

    //     usdtAsset.safeTransferFrom(msg.sender, address(this), _assets);
    //     usdtDeposited += _assets;
    //     usdtAsset.approve(address(mapleUSDTPool), _assets);
    //     usdtSharesReceived += mapleUSDTPool.deposit(_assets, address(this));

    // }

    // function requestRedeemUSDTMapleCash(uint256 _shares)public authorizedCaller returns(uint256){
    //     require(mapleUSDTPool.balanceOf(address(this)) >= _shares, "Insufficient amount");
    //     usdtSharesRequestedForRedeem = _shares;
    //     return mapleUSDTPool.requestRedeem(_shares, address(this));
    // }

    // function redeemUSDTMapleCash()public authorizedCaller{
    //     uint256 _shares = usdtSharesRequestedForRedeem;
    //     usdcRedeemed += mapleUSDTPool.redeem(_shares, nstblHub, address(this));
    // }

    function previewRedeemAsset(uint256 _shares) public authorizedCaller returns (uint256) {
        return mapleUSDCPool.previewRedeem(_shares / 10 ** 12);
    }

    function setAuthorizedCaller(address _caller) public onlyOwner {
        nstblHub = _caller;
    }

    // need a function for calculating shares that would be received
}
