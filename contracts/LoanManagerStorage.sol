// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "modules/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPool.sol";
import "./LMTokenLP.sol";

contract LoanManagerStorage {
    address public nstblHub;

    IERC20 public immutable usdc;
    IERC20 public usdtAsset;

    LMTokenLP public lUSDC;
    LMTokenLP public lUSDT;

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
