// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { LoanManagerStorage, IPool, IERC20, LMTokenLP } from "./LoanManagerStorage.sol";
import { console } from "forge-std/Test.sol";

contract LoanManager is Ownable, LoanManagerStorage {
    using SafeERC20 for IERC20;

    uint256 private _locked = 1;

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

    constructor(address _nstblHub, address _mapleUSDCPool, address _usdc, address _admin) Ownable(msg.sender) {
        nstblHub = _nstblHub;
        mapleUSDCPool = IPool(_mapleUSDCPool);
        // mapleUSDTPool = IPool(_mapleUSDTPool);
        usdc = IERC20(_usdc);
        // usdtAsset = IERC20(_USDTAsset);
        lUSDC = new LMTokenLP("Loan Manager USDC", "lUSDC", _admin);
        // console.log(lUSDC);
    }

    function investUSDCMapleCash(uint256 _assets) public authorizedCaller nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), _assets);
        usdcDeposited += _assets;
        usdc.approve(address(mapleUSDCPool), _assets);
        usdcSharesReceived = mapleUSDCPool.previewDeposit(_assets);
        mapleUSDCPool.deposit(_assets, address(this));
        totalUSDCSharesReceived += usdcSharesReceived;
        lUSDC.mint(nstblHub, usdcSharesReceived * 10 ** 12);
    }

    function requestRedeemUSDCMapleCash(uint256 _shares) public authorizedCaller nonReentrant {
        require(mapleUSDCPool.balanceOf(address(this)) >= _shares / 10 ** 12, "Insufficient amount");
        usdcSharesRequestedForRedeem = _shares;
        escrowedUSDCShares = mapleUSDCPool.requestRedeem(_shares / 10 ** 12, address(this));
    }

    function redeemUSDCMapleCash() public authorizedCaller nonReentrant {
        uint256 _shares = usdcSharesRequestedForRedeem;
        usdcRedeemed += mapleUSDCPool.redeem(_shares / 10 ** 12, nstblHub, address(this));
        lUSDC.burn(nstblHub, _shares * 10 ** 12);
        usdcSharesRequestedForRedeem = 0;
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
