// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ILoanManager {
    /*//////////////////////////////////////////////////////////////
    Events
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when Loan Manager is initialized
     * @param aclManager_ The address of ACL Manager
     * @param mapleUSDCPool_ The address of MAPLE USDC Pool
     * @param lUSDC_ The address of LP Token lUSDC
     */
    event LoanManagerInitialized(address aclManager_, address mapleUSDCPool_, address lUSDC_);

    /**
     * @dev Emitted when an amount is deposited from sender to this contract
     * @param asset_ The address of the asset being deposited
     * @param amount_ The amount of the asset being deposited
     * @param lTokens_ The amount of tokens minted
     * @param mapleShares_ The total shares after deposit is performed
     */
    event Deposit(address indexed asset_, uint256 amount_, uint256 lTokens_, uint256 mapleShares_);

    /**
     * @dev Emitted if there is a request to redeem the shares issued
     * @param asset_ The address of the asset to redeem
     * @param lTokens_ The amount of LP tokens to redeem
     * @param escrowedShares_ The total escrowed shares to be redeemed from maple
     */
    event RequestRedeem(address indexed asset_, uint256 lTokens_, uint256 escrowedShares_);

    /**
     * @dev Emitted when the issued shares are redeemed
     * @param asset_ The address of the asset to redeem
     * @param mapleShares_ The total escrowed shares redeemed from maple
     * @param tokensReceived_ The total tokens redeemed
     */
    event Redeem(address indexed asset_, uint256 mapleShares_, uint256 tokensReceived_);

    /**
     * @dev Emitted when the locked Maple Shares are removed
     * @param asset_ The address of the asset to remove
     * @param mapleShares_ The total escrowed shares redeemed from maple
     */
    event Removed(address indexed asset_, uint256 mapleShares_);

    /**
     * @dev Emitted when the address of nSTBL Hub is updated
     * @param oldHub_ The old address of the nSTBL Hub
     * @param newHub_ The updated address of the nSTBL Hub
     */
    event NSTBLHUBChanged(address indexed oldHub_, address indexed newHub_);

    /*//////////////////////////////////////////////////////////////
    Accounting
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit assets into the Maple Protocol pool and mint LP tokens (lUSDC) to the nSTBL Hub
     * @param amount_ The amount of the asset to deposit
     */
    function deposit(uint256 amount_) external;

    /**
     * @dev Request the redemption of LP tokens issued (lUSDC)
     * @param lpTokens_ The amount of LP tokens to redeem
     */
    function requestRedeem(uint256 lpTokens_) external;

    /**
     * @dev Redeem LP tokens issued (lUSDC)
     * @return stablesRedeemed The amount of shares redeemed
     */
    function redeem() external returns (uint256 stablesRedeemed);

    /**
     * @dev Remove Locked Maple Shares (during request redemption)
     */
    function remove() external;

    /*//////////////////////////////////////////////////////////////
    Views
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the number of LP tokens pending redemption for a specific LP token
     * @return lpTokensPendingRedemption_ The number of LP tokens pending redemption
     */
    function getLpTokensPendingRedemption() external view returns (uint256);

    /**
     * @dev Get the total assets represented by a given amount of LP tokens for a specific asset
     * @param lpTokens_ The amount of LP tokens to convert
     * @return The total assets represented by the LP tokens
     */
    function getAssets(uint256 lpTokens_) external view returns (uint256);

    /**
     * @dev Get the total assets with unrealized losses(from Maple Protocol's loans) represented by a given amount of LP tokens for a specific asset
     * @param lpTokens_ The amount of LP tokens to convert
     * @return The total assets with unrealized losses represented by the LP tokens
     */
    function getAssetsWithUnrealisedLosses(uint256 lpTokens_) external view returns (uint256);

    /**
     * @dev Get the number of shares (issued by Maple protocol pool to the Loan Manager) represented by a given amount of an asset
     * @param amount_ The amount of the asset to convert
     * @return The number of shares represented by the amount of the asset, or an error code if the asset is not supported
     */
    function getShares(uint256 amount_) external view returns (uint256);

    /**
     * @dev Get the number of exit shares represented by a given amount of an asset
     * @param amount_ The amount of the asset to convert
     * @return The number of exit shares represented by the amount of the asset, or an error code if the asset is not supported
     */
    function getExitShares(uint256 amount_) external view returns (uint256);

    /**
     * @dev Get the total unrealized losses (from Maple Protocol's loans) for a specific asset within the Maple Protocol pool
     * @return The total unrealized losses for the asset, or an error code if the asset is not supported
     */
    function getUnrealizedLossesMaple() external view returns (uint256);

    /**
     * @dev Get the total amount for a specific asset within the Maple Protocol pool
     * @return The total amount for the asset, or an error code if the asset is not supported
     */
    function getTotalAssetsMaple() external view returns (uint256);

    /**
     * @dev Preview the redemption of assets based on the given asset and number of LP tokens
     * @param lpTokens_ The number of LP tokens to be redeemed
     * @return The previewed amount of redeemed assets, or an error code if the asset is not supported
     */
    function previewRedeem(uint256 lpTokens_) external view returns (uint256);

    /**
     * @dev Preview the deposit of assets based on the given asset and amount
     * @param amount_ The amount of assets to be deposited
     * @return The previewed amount of shares that would be minted to the Loan Manager, or an error code if the asset is not supported
     */
    function previewDepositAssets(uint256 amount_) external view returns (uint256);

    /**
     * @dev Check if a deposit amount is valid based on the liquidity cap and total assets in the Maple Protocol pool
     * @param amount_ The amount to deposit
     * @return true if the deposit amount is valid; otherwise, false
     */
    function isValidDepositAmount(uint256 amount_) external view returns (bool);

    /**
     * @dev Get the maximum amount that can be deposited based on the liquidity cap and total assets in the Maple Protocol pool
     * @return upperBound The maximum amount that can be deposited
     */
    function getDepositUpperBound() external view returns (uint256 upperBound);
}
