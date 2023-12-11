// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./interfaces/maple/IPool.sol";
import "./interfaces/maple/IWithdrawalManager.sol";
import "./interfaces/IERC20Helper.sol";
import "@nstbl-acl-manager/contracts/IACLManager.sol";
import "./TokenLP.sol";

contract LoanManagerStorage {
    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice addresses of the maple pool managers for USDC cash pools
    address public immutable MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;

    /// @notice addresses of the maple withdrawal managers for USDC cash pools
    address public immutable MAPLE_WITHDRAWAL_MANAGER_USDC = 0x1146691782c089bCF0B19aCb8620943a35eebD12;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice slot 0 is utilized for the version of the contract
    uint256 public versionSlot;

    /// @notice address of USDC
    address public immutable usdc;

    /// @notice addresses of the maple pools for USDC
    address public mapleUSDCPool;

    /// @notice address of the LP tokens issued by Nealthy LoanManager for USDC
    TokenLP public lUSDC;

    /// @notice used to convert between maple LP token and Nealthy LoanManager's LP token
    uint256 public adjustedDecimals;

    /// @notice address of the NSTBL Hub
    address public nstblHub;

    /// @notice address of the Access Control Manager
    address public aclManager;

    /// @notice boolena flag to check for pending redemptions for an asset
    bool public awaitingRedemption;

    /// @notice to store total amount of an asset received for deposit
    uint256 public totalAssetsReceived;

    /// @notice to store total shares issued to the Loan Manager contract per asset
    uint256 public totalSharesReceived;

    /// @notice to store total amount of LP tokens minted
    uint256 public totalLPTokensMinted;

    /// @notice to store total amount of LP tokens burned
    uint256 public totalLPTokensBurned;

    /// @notice to store escrowed shares in the Maple protocol pool corresponding to each LP token
    uint256 public escrowedMapleShares;

    /// @notice mapping to store total assets received from Maple protocol pool after redemption
    uint256 public assetsRedeemed;

    /// @notice gap for adding future storage variables in the LoanManagerStorage contract
    uint256[38] _gap;
}
