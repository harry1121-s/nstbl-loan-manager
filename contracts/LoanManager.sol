// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./LoanManagerStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract loanManager is loanManagerStorage{

    using SafeERC20 for IERC20;

    // modifier authorizedCaller{
    //     require(msg.sender == nstblHub, "Loan Manager: unAuth");
    //     _;
    // }

    constructor(address _nstblHub, address _mapleCashPool, address _USDCToken){
        nstblHub = _nstblHub;
        mapleUSDCPool = IPool(_mapleCashPool);
        usdcToken = IERC20(_USDCToken);

    }

    function investUSDCMapleCash(uint256 _assets)public{

        usdcToken.safeTransferFrom(msg.sender, address(this), _assets);
        usdcDeposited += _assets;
        usdcToken.approve(address(mapleUSDCPool), _assets);
        mapleUSDCPool.deposit(_assets, address(this));
        usdcSharesReceived += mapleUSDCPool.balanceOf(address(this));

    }

    function requestRedeemUSDCMapleCash(uint256 _shares)public returns(uint256){
        require(mapleUSDCPool.balanceOf(address(this)) >= _shares, "Insufficient amount");
        usdcSharesRequestedForRedeem += _shares;
        return mapleUSDCPool.requestRedeem(_shares, address(this));
    }


}