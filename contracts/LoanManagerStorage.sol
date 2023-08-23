// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPool.sol";

contract loanManagerStorage{

    address public nstblHub;

    IERC20 public usdcToken;

    uint256 public usdcDeposited;

    uint256 public usdcSharesReceived;

    uint256 public usdcSharesRequestedForRedeem;

    IPool public mapleUSDCPool;
}