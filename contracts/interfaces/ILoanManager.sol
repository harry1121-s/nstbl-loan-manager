// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILoanManager {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed asset, uint256 amount);

    event RequestRedeem(address indexed asset, uint256 shares);

    event Redeem(address indexed asset, uint256 shares);

    /*//////////////////////////////////////////////////////////////
                                 LP Functions
    //////////////////////////////////////////////////////////////*/

    function deposit(address asset, uint256 amount) external;

    function requestRedeem(address asset, uint256 shares) external;

    function redeem(address asset, uint256 shares) external;

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function calculateShares(address asset, uint256 amount) external view returns (uint256);
    
    function calculateAssets(address asset, uint256 shares) external view returns (uint256);

    function unrealizedLosses(address asset, uint256 shares) external view returns (uint256);

}