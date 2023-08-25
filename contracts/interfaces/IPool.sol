// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPool {
    function deposit(uint256 _assets, address _receiver) external;
    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);
    function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowShares_);
    function convertToAssets(uint256 shares_) external returns (uint256 assets_);
    function previewRedeem(uint256 shares_) external returns (uint256 assets_);
    function balanceOf(address account) external view returns (uint256);
    function convertToExitAssets(uint256 shares_) external returns (uint256 assets_);
    function previewDeposit(uint256 assets_) external returns (uint256 shares_);
}
