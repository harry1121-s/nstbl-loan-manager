// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.21;

import "./interfaces/maple/IPool.sol";
import "./interfaces/maple/IWithdrawalManager.sol";
import "./interfaces/IERC20Helper.sol";
import "./LMTokenLP.sol";

contract LoanManagerStorage {
    event Deposit(address indexed asset, uint256 amount, uint256 lTokens, uint256 mapleShares);

    event RequestRedeem(address indexed asset, uint256 lTokens, uint256 escrowedShares);

    event Redeem(address indexed asset, uint256 shares, uint256 tokensReceived);

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public immutable ERR_CODE = type(uint256).max - 1;

    /// @notice addresses of USDC and USDT
    address public immutable usdc;
    address public immutable usdt;

    /// @notice addresses of the maple pools for USDC and USDT
    /// @dev is immutable to allow for changes during upgrades (in case of changes on Maple's side)
    address public immutable mapleUSDCPool;
    address public immutable mapleUSDTPool;

    /// @notice addresses of the maple pool managers for USDC and USDT cash pools
    /// @dev is immutable to allow for changes during upgrades (in case of changes on Maple's side)
    address public immutable MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;
    address public immutable MAPLE_POOL_MANAGER_USDT = 0xE76b219f83E887E2503E14c343Bb7E0B62A7Af5d;

    /// @notice addresses of the maple withdrawal managers for USDC and USDT cash pools
    /// @dev is immutable to allow for changes during upgrades (in case of changes on Maple's side)
    address public immutable MAPLE_WITHDRAWAL_MANAGER_USDC = 0x1146691782c089bCF0B19aCb8620943a35eebD12;
    address public immutable MAPLE_WITHDRAWAL_MANAGER_USDT = 0xF0A66F70064aD3198Abb35AAE26B1eeeaEa62C4B;

    /// @notice addresses of the LP tokens issued by Nealthy LoanManager for USDC and USDT
    /// @dev is immutable since tokens are deployed in the constructor
    LMTokenLP public immutable lUSDC;
    LMTokenLP public immutable lUSDT;

    /// @notice used to convert between maple LP token and Nealthy LoanManager's LP token
    uint256 public immutable adjustedDecimals;

    /// @notice address of the admin
    address public immutable admin;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the NSTBL Hub
    address public nstblHub;

    mapping(address => bool) public awaitingRedemption;
    mapping(address => uint256) public totalAssetsReceived;
    mapping(address => uint256) public totalSharesReceived;
    mapping(address => uint256) public totalLPTokensMinted;
    mapping(address => uint256) public totalLPTokensBurned;

    mapping(address => uint256) public escrowedMapleShares;
    mapping(address => uint256) public assetsRedeemed;
}
