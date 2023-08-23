// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./LoanManagerStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract loanManager is loanManagerStorage{

    using SafeERC20 for IERC20;

    modifier authorizedCaller{
        require(msg.sender == nstblHub, "Loan Manager: unAuth");
        _;
    }

    constructor(
        address _nstblHub, 
        address _mapleUSDCPool, 
        address _mapleUSDTPool, 
        address _USDCAsset, 
        address _USDTAsset){
        nstblHub = _nstblHub;
        mapleUSDCPool = IPool(_mapleUSDCPool);
        mapleUSDTPool = IPool(_mapleUSDTPool);
        usdcAsset = IERC20(_USDCAsset);
        usdtAsset = IERC20(_USDTAsset);

    }

    function investUSDCMapleCash(uint256 _assets)public authorizedCaller{

        usdcAsset.safeTransferFrom(msg.sender, address(this), _assets);
        usdcDeposited += _assets;
        usdcAsset.approve(address(mapleUSDCPool), _assets);
        usdcSharesReceived += mapleUSDCPool.deposit(_assets, address(this));
    }

    function requestRedeemUSDCMapleCash(uint256 _shares)public authorizedCaller returns(uint256){
        require(mapleUSDCPool.balanceOf(address(this)) >= _shares, "Insufficient amount");
        usdcSharesRequestedForRedeem = _shares;
        return mapleUSDCPool.requestRedeem(_shares, address(this));
    }

    function redeemUSDCMapleCash()public authorizedCaller{
        uint256 _shares = usdcSharesRequestedForRedeem;
        usdcRedeemed += mapleUSDCPool.redeem(_shares, nstblHub, address(this));

    }

    function investUSDTMapleCash(uint256 _assets)public authorizedCaller{

        usdtAsset.safeTransferFrom(msg.sender, address(this), _assets);
        usdtDeposited += _assets;
        usdtAsset.approve(address(mapleUSDTPool), _assets);
        usdtSharesReceived += mapleUSDTPool.deposit(_assets, address(this));

    }

    function requestRedeemUSDTMapleCash(uint256 _shares)public authorizedCaller returns(uint256){
        require(mapleUSDTPool.balanceOf(address(this)) >= _shares, "Insufficient amount");
        usdtSharesRequestedForRedeem = _shares;
        return mapleUSDTPool.requestRedeem(_shares, address(this));
    }

    function redeemUSDTMapleCash()public authorizedCaller{
        uint256 _shares = usdtSharesRequestedForRedeem;
        usdcRedeemed += mapleUSDTPool.redeem(_shares, nstblHub, address(this));


    }

}