// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./interfaces/IPool.sol";
import "./interfaces/IERC20Helper.sol";
import "./LMTokenLP.sol";

contract LoanManagerStorage {
    event Deposit(address indexed asset, uint256 amount, uint256 lTokens, uint256 mapleShares);

    event RequestRedeem(address indexed asset, uint256 lTokens, uint256 escrowedShares);

    event Redeem(address indexed asset, uint256 shares, uint256 tokensReceived);

    address public nstblHub;
    address public admin;

    address public immutable usdc;
    address public immutable usdt;

    LMTokenLP public lUSDC;
    LMTokenLP public lUSDT;

    uint256 public adjustedDecimals;

    mapping(address => bool) public awaitingRedemption;
    mapping(address => uint256) public totalAssetsReceived;
    mapping(address => uint256) public totalSharesReceived;
    mapping(address => uint256) public totalLPTokensMinted;
    mapping(address => uint256) public totalLPTokensBurned;

    mapping(address => uint256) public lpTokensRequestedForRedeem;
    mapping(address => uint256) public escrowedMapleShares;
    mapping(address => uint256) public assetsRedeemed;

    address public mapleUSDCPool;

    address public mapleUSDTPool;
}
