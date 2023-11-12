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

}
