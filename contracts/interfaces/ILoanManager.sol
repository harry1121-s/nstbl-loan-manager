// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ILoanManager {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when an amount is deposited from sender to this contract
     * @param asset The address of the asset being deposited
     * @param amount The amount of the asset being deposited
     * @param lTokens The amount of tokens minted
     * @param mapleShares The total shares after deposit is performed
     */
    event Deposit(address indexed asset, uint256 amount, uint256 lTokens, uint256 mapleShares);

    /**
     * @dev Emitted if there is a request to redeem the shares issued
     * @param asset The address of the asset to redeem
     * @param lTokens The amount of LP tokens to redeem
     * @param escrowedShares The total escrowed shares to be redeemed from maple
     */
    event RequestRedeem(address indexed asset, uint256 lTokens, uint256 escrowedShares);

    /**
     * @dev Emitted when the issued shares are redeemed
     * @param asset The address of the asset to redeem
     * @param mapleShares The total escrowed shares redeemed from maple
     * @param tokensReceived The total tokens redeemed
     */
    event Redeem(address indexed asset, uint256 mapleShares, uint256 tokensReceived);

    /**
     * @dev Emitted when the locked Maple Shares are removed
     * @param asset The address of the asset to remove
     * @param mapleShares The total escrowed shares redeemed from maple
     */
    event Removed(address indexed asset, uint256 mapleShares);

    /**
     * @dev Emitted when the address of nSTBL Hub is updated
     * @param oldHub The old address of the nSTBL Hub
     * @param newHub The updated address of the nSTBL Hub
     */
    event NSTBLHUBChanged(address indexed oldHub, address indexed newHub);

    /*//////////////////////////////////////////////////////////////
                                 LP Functions
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
    function redeem() external returns(uint256 stablesRedeemed);

    /**
     * @dev Remove Locked Maple Shares (during request redemption)
     */
    function remove() external;

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the number of LP tokens pending redemption for a specific LP token
     * @return The number of LP tokens pending redemption
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
     * @dev Get the number of exit shares represented by a given amount of an asset.
     * @param amount_ The amount of the asset to convert.
     * @return The number of exit shares represented by the amount of the asset, or an error code if the asset is not supported.
     */
    function getExitShares(uint256 amount_) external view returns (uint256);

    /**
     * @dev Get the total unrealized losses (from Maple Protocol's loans) for a specific asset within the Maple Protocol pool.
     * @return The total unrealized losses for the asset, or an error code if the asset is not supported.
     */
    function getUnrealizedLossesMaple() external view returns (uint256);

    /**
     * @dev Get the total amount for a specific asset within the Maple Protocol pool.
     * @return The total amount for the asset, or an error code if the asset is not supported.
     */
    function getTotalAssetsMaple() external view returns (uint256);

    /**
     * @dev Preview the redemption of assets based on the given asset and number of LP tokens.
     * @param lpTokens_ The number of LP tokens to be redeemed.
     * @return The previewed amount of redeemed assets, or an error code if the asset is not supported.
     */
    function previewRedeem(uint256 lpTokens_) external view returns (uint256);

    /**
     * @dev Preview the deposit of assets based on the given asset and amount.
     * @param amount_ The amount of assets to be deposited.
     * @return The previewed amount of shares that would be minted to the Loan Manager, or an error code if the asset is not supported.
     */
    function previewDepositAssets(uint256 amount_) external view returns (uint256);

    /**
     * @dev Check if a deposit amount is valid based on the liquidity cap and total assets in the Maple Protocol pool.
     * @param amount_ The amount to deposit.
     * @param pool_ The address of the Maple Protocol pool contract.
     * @param poolManager_ The address of the Maple Protocol pool manager contract.
     * @return true if the deposit amount is valid; otherwise, false.
     */
    function isValidDepositAmount(uint256 amount_, address pool_, address poolManager_) external view returns (bool);

    /**
     * @dev Get the maximum amount that can be deposited based on the liquidity cap and total assets in the Maple Protocol pool.
     * @return upperBound The maximum amount that can be deposited.
     */
    function getDepositUpperBound() external view returns (uint256 upperBound);
}
