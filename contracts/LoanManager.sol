// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./interfaces/ILoanManager.sol";
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

    modifier nonReentrant() {
        require(_locked == 1, "P:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(address _nstblHub, address _mapleUSDCPool, address _mapleUSDTPool, address _usdc, address _usdt, address _admin) Ownable(msg.sender) {
        nstblHub = _nstblHub;
        mapleUSDCPool = IPool(_mapleUSDCPool);
        mapleUSDTPool = IPool(_mapleUSDTPool);
        usdc = IERC20(_usdc);
        usdt = IERC20(_usdt);
        lUSDC = new LMTokenLP("Loan Manager USDC", "lUSDC", _admin);
        lUSDT = new LMTokenLP("Loan Manager USDT", "lUSDT", _admin);
        adjustedDecimals = lUSDC.decimals()-mapleUSDCPool.decimals();
    }

    function deposit(address _asset, uint256 _amount) public authorizedCaller nonReentrant {
        require(_asset != address(0), "LM: Invalid Target address");
        require( _amount > 0, "LM: Insufficient amount");

        if(_asset == address(usdc)){
            _investUSDCMapleCash(_amount);
        }
        else if(_asset == address(usdt)){
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
        uint256 lpTokens = usdcSharesReceived * 10**adjustedDecimals;
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
        uint256 lpTokens = usdtSharesReceived * 10**adjustedDecimals;
        lUSDT.mint(nstblHub, lpTokens);
        emit Deposit(address(usdt), _amount, lpTokens, usdtSharesReceived);

    }
    
    function requestRedeem(address _asset, uint256 _lmTokens) public authorizedCaller nonReentrant {
        require(_asset != address(0), "LM: Invalid Target address");
        require( _lmTokens > 0, "LM: Insufficient amount");

        if(_asset == address(usdc)){
            _requestRedeemUSDCMapleCash(_lmTokens);
        }
        else if(_asset == address(usdt)){
            _requestRedeemUSDTMapleCash(_lmTokens);
        }
    }

    function _requestRedeemUSDCMapleCash(uint256 _lmTokens) internal {
        require(!awaitingUSDCRedemption, "LM: USDC Redemption Pending");
        require(mapleUSDCPool.balanceOf(address(this)) >= _lmTokens / 10**adjustedDecimals, "Insufficient amount");
        lusdcRequestedForRedeem = _lmTokens;
        escrowedMapleUSDCShares = mapleUSDCPool.requestRedeem(_lmTokens / 10**adjustedDecimals, address(this));
        lUSDC.transferFrom(msg.sender, address(this), _lmTokens);
        awaitingUSDCRedemption = true;
    }

    function _requestRedeemUSDTMapleCash(uint256 _lmTokens) internal {
        require(!awaitingUSDTRedemption, "LM: USDT Redemption Pending");
        require(mapleUSDTPool.balanceOf(address(this)) >= _lmTokens / 10**adjustedDecimals, "Insufficient amount");
        lusdtRequestedForRedeem = _lmTokens;
        escrowedMapleUSDTShares = mapleUSDTPool.requestRedeem(_lmTokens / 10**adjustedDecimals, address(this));
        lUSDT.transferFrom(msg.sender, address(this), _lmTokens);
        awaitingUSDTRedemption = true;
    }

    // function redeemUSDCMapleCash() public authorizedCaller nonReentrant {
    //     uint256 _shares = usdcSharesRequestedForRedeem;
    //     usdcRedeemed += mapleUSDCPool.redeem(_shares / 10 ** 12, nstblHub, address(this));
    //     lUSDC.burn(nstblHub, _shares * 10 ** 12);
    //     usdcSharesRequestedForRedeem = 0;
    // }

    function depositPreview() public returns (uint256){

    }
    function getAssets(uint256 _shares) public returns (uint256) {
        return mapleUSDCPool.convertToAssets(_shares / 10 ** 12);
    }

    function getAssetsWithUnrealisedLosses(uint256 _shares) public returns (uint256) {
        return mapleUSDCPool.convertToExitAssets(_shares / 10 ** 12);
    }

    function getShares(uint256 _assets) public returns(uint256) {
        return mapleUSDCPool.convertToShares(_assets);
    }

    function getExitShares(uint256 _assets) public returns (uint256){
        return mapleUSDCPool.convertToExitShares(_assets);
    }

    function getUnrealizedLosses() public returns (uint256) {
        return mapleUSDCPool.unrealizedLosses();
    }

    function getTotalAssets() public returns (uint256) {
        return mapleUSDCPool.totalAssets();
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
