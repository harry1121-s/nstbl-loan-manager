// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ILoanManager {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed asset, uint256 amount, uint256 lTokens, uint256 mapleShares);

    event RequestRedeem(address indexed asset, uint256 lTokens, uint256 escrowedShares);

    event Redeem(address indexed asset, uint256 mapleShares, uint256 tokensReceived);

    event Removed(address indexed asset, uint256 mapleShares);

    event NSTBLHUBChanged(address indexed oldHub, address indexed newHub);

    /*//////////////////////////////////////////////////////////////
                                 LP Functions
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount_) external;

    function requestRedeem(uint256 lpTokens_) external;

    function redeem() external returns(uint256);

    function remove() external;

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function getLpTokensPendingRedemption() external view returns (uint256);

    function getAssets(uint256 lpTokens_) external view returns (uint256);

    function getAssetsWithUnrealisedLosses(uint256 lpTokens_) external view returns (uint256);
    
    function getShares(uint256 amount_) external view returns (uint256);

    function getExitShares(uint256 amount_) external view returns (uint256);

    function getUnrealizedLossesMaple() external view returns (uint256);

    function getTotalAssetsMaple() external view returns (uint256);

    function previewRedeem(uint256 lpTokens_) external view returns (uint256);

    function previewDepositAssets(uint256 amount_) external view returns (uint256);

    function isValidDepositAmount(uint256 amount_, address pool_, address poolManager_) external view returns (bool);

    function getDepositUpperBound() external view returns (uint256 upperBound);

}
