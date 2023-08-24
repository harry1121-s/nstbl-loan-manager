// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LoanManagerStorage.sol";
import "./Token.sol";
import { console } from "forge-std/Test.sol";

contract loanManager is Ownable, loanManagerStorage {
    using SafeERC20 for IERC20;

    modifier authorizedCaller() {
        require(msg.sender == nstblHub, "Loan Manager: unAuth");
        _;
    }

    constructor(
        address _nstblHub,
        address _mapleUSDCPool,
        // address _mapleUSDTPool,
        address _usdc,
        // address _USDTAsset
        address _lUSDC
    ) Ownable(msg.sender) {
        nstblHub = _nstblHub;
        mapleUSDCPool = IPool(_mapleUSDCPool);
        // mapleUSDTPool = IPool(_mapleUSDTPool);
        usdc = IERC20(_usdc);
        // usdtAsset = IERC20(_USDTAsset);
        lUSDC = IERC20(_lUSDC);
    }

    function investUSDCMapleCash(uint256 _assets) public authorizedCaller {
        usdc.safeTransferFrom(msg.sender, address(this), _assets);
        usdcDeposited += _assets;
        // uint256 getShares
        usdc.approve(address(mapleUSDCPool), _assets);
        mapleUSDCPool.deposit(_assets, address(this));
        // totalUSDCSharesReceived += mapleUSDCPool.deposit(_assets, address(this));

        // lUSDC.mint(nstblHub, usdcSharesReceived * (lUSDC.decimals() / mapleUSDCPool.decimals()));
    }

    function requestRedeemUSDCMapleCash(uint256 _shares) public authorizedCaller {
        require(mapleUSDCPool.balanceOf(address(this)) >= _shares, "Insufficient amount");
        usdcSharesRequestedForRedeem = _shares;
        escrowedUSDCShares = mapleUSDCPool.requestRedeem(_shares, address(this));
    }
 
    // function getAssets(uint256 _shares) public view returns (uint256) {
    //     return mapleUSDCPool.convertToAssets(_shares);
    // }

    // function getAssetsWithUnRealisedLosses(uint256 _shares) public view returns (uint256) {
    //     return mapleUSDCPool.convertToExitAssets(_shares);
    // }

    // function redeemUSDCMapleCash()public authorizedCaller{
    //     uint256 _shares = usdcSharesRequestedForRedeem;
    //     usdcRedeemed += mapleUSDCPool.redeem(_shares, nstblHub, address(this));

    // }

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
        return mapleUSDCPool.previewRedeem(_shares);
    }

    function setAuthorizedCaller(address _caller) public onlyOwner {
        nstblHub = _caller;
    }
}
