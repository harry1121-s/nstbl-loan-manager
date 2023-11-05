// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./interfaces/maple/IPool.sol";
import "./interfaces/maple/IWithdrawalManager.sol";
import "./interfaces/IERC20Helper.sol";
import "@nstbl-acl-manager/contracts/IACLManager.sol";
import "./TokenLP.sol";

contract LoanManagerStorage {
    event Deposit(address indexed asset, uint256 amount, uint256 lTokens, uint256 mapleShares);

    event RequestRedeem(address indexed asset, uint256 lTokens, uint256 escrowedShares);

    event Redeem(address indexed asset, uint256 mapleShares, uint256 tokensReceived);

    event Removed(address indexed asset, uint256 mapleShares);

    event NSTBLHUBChanged(address indexed oldHub, address indexed newHub);

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    error InvalidAsset();
    uint256 public immutable ERR_CODE = type(uint256).max - 1;

    /// @notice addresses of USDC and USDT
    address public immutable usdc;

    /// @notice addresses of the maple pools for USDC and USDT
    /// @dev is immutable to allow for changes during upgrades (in case of changes on Maple's side)
    address public mapleUSDCPool;

    /// @notice addresses of the maple pool managers for USDC and USDT cash pools
    /// @dev is immutable to allow for changes during upgrades (in case of changes on Maple's side)
    address public immutable MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;

    /// @notice addresses of the maple withdrawal managers for USDC and USDT cash pools
    /// @dev is immutable to allow for changes during upgrades (in case of changes on Maple's side)
    address public immutable MAPLE_WITHDRAWAL_MANAGER_USDC = 0x1146691782c089bCF0B19aCb8620943a35eebD12;

    /// @notice addresses of the LP tokens issued by Nealthy LoanManager for USDC and USDT
    /// @dev is immutable since tokens are deployed in the constructor
    TokenLP public lUSDC;

    /// @notice used to convert between maple LP token and Nealthy LoanManager's LP token
    uint256 public adjustedDecimals;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the NSTBL Hub
    address public nstblHub;

    /// @notice address of the Access Control Manager
    address public aclManager;

    /// @notice mapping to check for pending redemptions for an asset
    mapping(address => bool) public awaitingRedemption;

    /// @notice mapping to store total amount of an asset received for deposit
    mapping(address => uint256) public totalAssetsReceived;

    /// @notice mapping to store total shares issued to the Loan Manager contract per asset
    mapping(address => uint256) public totalSharesReceived;

    /// @notice mapping to store total amount of LP tokens minted
    mapping(address => uint256) public totalLPTokensMinted;

    /// @notice mapping to store total amount of LP tokens burned
    mapping(address => uint256) public totalLPTokensBurned;

    /// @notice mapping to store escrowed shares in the Maple protocol pool corresponding to each LP token
    mapping(address => uint256) public escrowedMapleShares;

    /// @notice mapping to store total assets received per asset from Maple protocol pool after redemption
    mapping(address => uint256) public assetsRedeemed;


    ////New storage variables

    uint256 immutable precision = 10**27;
}