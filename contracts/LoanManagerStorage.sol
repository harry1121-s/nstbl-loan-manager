// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPool.sol";

contract loanManagerStorage{

    address public nstblHub;

    IERC20 public immutable usdcAsset;
    IERC20 public usdtAsset;

    IERC20 public  immutable lUSDC;
    IERC20 public lUSDT;

    uint256 public usdcDeposited;
    uint256 public usdcSharesReceived;
    uint256 public totalUSDCSharesReceived;
    uint256 public escrowedUSDCShares;


    uint256 public usdcRedeemed;


    uint256 public usdcSharesRequestedForRedeem;

    uint256 public usdtDeposited;

    uint256 public usdtRedeemed;

    uint256 public usdtSharesReceived;

    uint256 public usdtSharesRequestedForRedeem;

    IPool public mapleUSDCPool;

    IPool public mapleUSDTPool;

}