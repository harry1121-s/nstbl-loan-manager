// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "modules/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPool.sol";
import "./LMTokenLP.sol";

contract LoanManagerStorage {
    event Deposit(address indexed asset, uint256 amount, uint256 lTokens, uint256 mapleShares);

    event RequestRedeem(address indexed asset, uint256 shares);

    event Redeem(address indexed asset, uint256 shares);

    address public nstblHub;

    IERC20 public immutable usdc;
    IERC20 public usdt;

    LMTokenLP public lUSDC;
    LMTokenLP public lUSDT;

    uint256 public adjustedDecimals;
    bool public awaitingUSDCRedemption;
    bool public awaitingUSDTRedemption;

    uint256 public usdcDeposited;
    uint256 public usdcSharesReceived;
    uint256 public totalUSDCSharesReceived;
    uint256 public lusdcRequestedForRedeem;
    uint256 public escrowedMapleUSDCShares;
    uint256 public usdcRedeemed;

    uint256 public usdtDeposited;
    uint256 public usdtSharesReceived;
    uint256 public totalUSDTSharesReceived;
    uint256 public lusdtRequestedForRedeem;
    uint256 public escrowedMapleUSDTShares;
    uint256 public usdtRedeemed;

    IPool public mapleUSDCPool;

    IPool public mapleUSDTPool;
}
