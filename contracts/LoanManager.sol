// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { VersionedInitializable } from "./upgradeable/VersionedInitializable.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import {
    IPool,
    IERC20Helper,
    IWithdrawalManagerStorage,
    IWithdrawalManager,
    IACLManager,
    TokenLP,
    LoanManagerStorage
} from "./LoanManagerStorage.sol";

/**
 * @title LoanManager contract for managing investment Maple Protocol's USDC CASHPool
 * @author 0xangad, Harshit Singhal
 * @notice This contract is intended to be used by NSTBL hub and future nealthy products
 * @dev This contract allows NSTBL hub to deposit assets into Maple Protocol pools, request and redeem Maple Protocol tokens, and perform various other loan management operations
 */

contract LoanManager is ILoanManager, LoanManagerStorage, VersionedInitializable {
    using SafeERC20 for IERC20Helper;
    using Address for address;

    uint256 private _locked;

    /*//////////////////////////////////////////////////////////////
    Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier to ensure that only authorized callers can execute a function
     */
    modifier authorizedCaller() {
        require(IACLManager(aclManager).authorizedCallersLoanManager(msg.sender), "Loan Manager: unAuth Hub");
        _;
    }

    /**
     * @dev Modifier to ensure that only the admin can execute a function
     */
    modifier onlyAdmin() {
        require(msg.sender == IACLManager(aclManager).admin(), "LM: unAuth Admin");
        _;
    }

    /**
     * @dev Modifier to validate input parameters
     */
    modifier validInput(uint256 _amount) {
        require(_amount > 0, "LM: Insufficient amount");
        _;
    }

    /**
     * @dev Modifier to prevent reentrancy attacks
     */
    modifier nonReentrant() {
        require(_locked == 1, "LM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
    Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor to set immutables for the LoanManager contract
     */
    constructor() {
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    //function to initialize the storage in the proxy contract
    function initialize(address aclManager_, address mapleUSDCPool_) external initializer {
        _zeroAddressCheck(aclManager_);
        _zeroAddressCheck(mapleUSDCPool_);
        mapleUSDCPool = mapleUSDCPool_;
        aclManager = aclManager_;
        lUSDC = new TokenLP("Loan Manager USDC", "lUSDC", aclManager_);
        adjustedDecimals = lUSDC.decimals() - IPool(mapleUSDCPool).decimals();
        _locked = 1;
        emit LoanManagerInitialized(aclManager_, mapleUSDCPool_, address(lUSDC));
    }

    /*//////////////////////////////////////////////////////////////
    Externals - accounting
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoanManager
     * @dev Deposit assets into the Maple Protocol pool and mint LP tokens (lUSDC) to the nSTBL Hub
     * @notice The LP tokens corresponding to the shares issued by the Maple Protocol pool are minted
     * @param amount_ The amount of the asset to deposit
     */
    function deposit(uint256 amount_) external authorizedCaller nonReentrant {
        _depositMapleCash(amount_, usdc, mapleUSDCPool, address(lUSDC));
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Request the redemption of LP tokens issued (lUSDC)
     * @notice The shares corresponding to the LP tokens are requested for redemption from the Maple Protocol pool
     * @param lpTokens_ The amount of LP tokens to redeem
     */
    function requestRedeem(uint256 lpTokens_) external authorizedCaller nonReentrant validInput(lpTokens_) {
        _requestRedeemMapleCash(lpTokens_, usdc, mapleUSDCPool);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Redeem LP tokens issued (lUSDC)
     * @notice The shares corresponding to the LP tokens that were requested for redemption are redeemed from the Maple Protocol pool
     * @notice The shares are burned in the Maple Protocol pool contract and the LP tokens are burned here
     * @return stablesRedeemed_ The amount of stables received from maple
     */
    function redeem() external authorizedCaller nonReentrant returns (uint256 stablesRedeemed_) {
        require(awaitingRedemption, "LM: No redemption requested");
        stablesRedeemed_ = _redeemMapleCash(usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Remove Locked Maple Shares (during request redemption)
     * @notice The shares corresponding to the LP tokens that were requested for redemption are removed from the Maple Protocol pool
     * @notice The shares are transferred Maple Protocol's withdrawal manager contract back to Nealthy's loan Manager
     */
    function remove() external authorizedCaller nonReentrant {
        require(awaitingRedemption, "LM: No Tokens to remove");
        _removeMapleCash(usdc, mapleUSDCPool, MAPLE_WITHDRAWAL_MANAGER_USDC);
    }

    /**
     * @dev To withdraw tokens from the address of the asset
     * @param asset_ The address of the asset from where the tokens are withdrawn
     * @param amount_ The amount of the asset to be withdrawn
     * @param destination_ The address to which the amount is transferred
     */
    function withdrawTokens(address asset_, uint256 amount_, address destination_) external authorizedCaller {
        IERC20Helper(asset_).safeTransfer(destination_, amount_);
    }

    /*//////////////////////////////////////////////////////////////
    Views
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoanManager
     * @dev Get the number of LP tokens pending redemption for a specific LP token
     * @return lpTokensPendingRedemption_ The number of LP tokens pending redemption, adjusted to the contract's decimals
     */
    function getLpTokensPendingRedemption() external view returns (uint256 lpTokensPendingRedemption_) {
        lpTokensPendingRedemption_ = escrowedMapleShares * 10 ** adjustedDecimals;
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the total assets represented by a given amount of LP tokens for a specific asset
     * @param lpTokens_ The amount of LP tokens to convert
     * @return assets_ The total assets represented by the LP tokens, adjusted to the contract's decimals, or an error code if the asset is not supported
     */
    function getAssets(uint256 lpTokens_) external view validInput(lpTokens_) returns (uint256 assets_) {
        assets_ = IPool(mapleUSDCPool).convertToAssets(lpTokens_ / 10 ** adjustedDecimals);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the total assets with unrealized losses(from Maple Protocol's loans) represented by a given amount of LP tokens for a specific asset
     * @param lpTokens_ The amount of LP tokens to convert
     * @return assetsWithUnrealisedLosses_ The total assets with unrealized losses represented by the LP tokens, adjusted to the contract's decimals, or an error code if the asset is not supported
     */
    function getAssetsWithUnrealisedLosses(uint256 lpTokens_)
        external
        view
        validInput(lpTokens_)
        returns (uint256 assetsWithUnrealisedLosses_)
    {
        assetsWithUnrealisedLosses_ = IPool(mapleUSDCPool).convertToExitAssets(lpTokens_ / 10 ** adjustedDecimals);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the number of shares (issued by Maple protocol pool to the Loan Manager) represented by a given amount of an asset
     * @param amount_ The amount of the asset to convert
     * @return shares_ The number of shares represented by the amount of the asset, or an error code if the asset is not supported
     */
    function getShares(uint256 amount_) external view validInput(amount_) returns (uint256 shares_) {
        shares_ = IPool(mapleUSDCPool).convertToShares(amount_);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the number of exit shares represented by a given amount of an asset
     * @param amount_ The amount of the asset to convert
     * @return exitShares_ The number of exit shares represented by the amount of the asset, or an error code if the asset is not supported
     */
    function getExitShares(uint256 amount_) external view validInput(amount_) returns (uint256 exitShares_) {
        exitShares_ = IPool(mapleUSDCPool).convertToExitShares(amount_);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the total unrealized losses (from Maple Protocol's loans) for a specific asset within the Maple Protocol pool
     * @return unrealizedLosses_ The total unrealized losses for the asset, or an error code if the asset is not supported
     */
    function getUnrealizedLossesMaple() external view returns (uint256 unrealizedLosses_) {
        unrealizedLosses_ = IPool(mapleUSDCPool).unrealizedLosses();
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the total amount for a specific asset within the Maple Protocol pool
     * @return assets_ The total amount for the asset, or an error code if the asset is not supported
     */
    function getTotalAssetsMaple() external view returns (uint256 assets_) {
        assets_ = IPool(mapleUSDCPool).totalAssets();
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Preview the redemption of assets based on the given asset and number of LP tokens
     * @notice This function returns correct value only when a redemption has been requested and when called within the redemption window
     * @param lpTokens_ The number of LP tokens to be redeemed
     * @return assetsRedeemable_ The previewed amount of redeemed assets, or an error code if the asset is not supported
     */
    function previewRedeem(uint256 lpTokens_) external view returns (uint256 assetsRedeemable_) {
        assetsRedeemable_ = IPool(mapleUSDCPool).previewRedeem(lpTokens_ / 10 ** adjustedDecimals);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Preview the deposit of assets based on the given asset and amount
     * @param amount_ The amount of assets to be deposited
     * @return assetsDeposit_ The previewed amount of shares that would be minted to the Loan Manager, or an error code if the asset is not supported
     */
    function previewDepositAssets(uint256 amount_) external view returns (uint256 assetsDeposit_) {
        assetsDeposit_ = IPool(mapleUSDCPool).previewDeposit(amount_);
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Check if a deposit amount is valid based on the liquidity cap and total assets in the Maple Protocol pool
     * @param amount_ The amount to deposit
     * @return isValid_ true if the deposit amount is valid; otherwise, false
     */
    function isValidDepositAmount(uint256 amount_) public view returns (bool isValid_) {
        bytes memory val = MAPLE_POOL_MANAGER_USDC.functionStaticCall(abi.encodeWithSignature("liquidityCap()"));
        uint256 upperBound = uint256(bytes32(val));
        uint256 totalAssets = IPool(mapleUSDCPool).totalAssets();
        uint256 shares = IPool(mapleUSDCPool).previewDeposit(amount_);
        isValid_ = (shares > 0) && (amount_ < (upperBound - totalAssets)) ? true : false;
    }

    /**
     * @inheritdoc ILoanManager
     * @dev Get the maximum amount that can be deposited based on the liquidity cap and total assets in the Maple Protocol pool
     * @return upperBound_ The maximum amount that can be deposited
     */
    function getDepositUpperBound() external view returns (uint256 upperBound_) {
        bytes memory val = MAPLE_POOL_MANAGER_USDC.functionStaticCall(abi.encodeWithSignature("liquidityCap()"));
        uint256 ub = uint256(bytes32(val));
        uint256 totalAssets = IPool(mapleUSDCPool).totalAssets();
        upperBound_ = ub - totalAssets;
    }

    /**
     * @dev Get the balance of tokens in the pool
     * @param asset_ The address of the asset to redeem
     * @return value_ The total balance of tokens
     */
    function getAirdroppedTokens(address asset_) external view returns (uint256 value_) {
        value_ = IERC20Helper(asset_).balanceOf(address(this));
    }

    /**
     * @dev Get the matured amount of assets
     * @return value_ The total matured assets
     */
    function getMaturedAssets() external view returns (uint256 value_) {
        value_ =
            IPool(mapleUSDCPool).convertToAssets(lUSDC.totalSupply() / 10 ** adjustedDecimals) * 10 ** adjustedDecimals;
    }

    /**
     * @dev Get the total supply of USDC
     * @return value_ The total value of USDC supply
     */
    function getLPTotalSupply() external view returns (uint256 value_) {
        value_ = lUSDC.totalSupply();
    }

    /**
     * @dev Get the implementation contract version
     * @return revision_ The implementation contract version
     */
    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = REVISION;
    }

    /**
     * @dev Get the implementation contract version
     * @return version_ The implementation contract version
     */
    function getVersion() public pure returns (uint256 version_) {
        version_ = getRevision();
    }

    /**
     * @dev Get the total time period for redemption
     * @return windowStart_ The starting time of the window
     * @return windowEnd_ The ending time of the window
     */
    function getRedemptionWindow() external view returns (uint256 windowStart_, uint256 windowEnd_) {
        require(awaitingRedemption, "LM: No redemption requested");
        uint256 exitCycleId = IWithdrawalManagerStorage(MAPLE_WITHDRAWAL_MANAGER_USDC).exitCycleId(address(this));
        (windowStart_, windowEnd_) = IWithdrawalManager(MAPLE_WITHDRAWAL_MANAGER_USDC).getWindowAtId(exitCycleId);
    }

    /*//////////////////////////////////////////////////////////////
    Externals - setters
    //////////////////////////////////////////////////////////////*/

    //function to set the address of NSTBL hub
    function updateNSTBLHUB(address nstblHub_) external onlyAdmin {
        _zeroAddressCheck(nstblHub_);
        address oldNstblHub = nstblHub;
        nstblHub = nstblHub_;
        emit NSTBLHUBChanged(oldNstblHub, nstblHub);
    }

    /*//////////////////////////////////////////////////////////////
    Internals
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to deposit assets into the Maple Protocol pool and mint LP tokens
     * @param amount_ The amount of the asset to deposit
     * @param asset_ The address of the asset being deposited
     * @param pool_ The address of the Maple Protocol pool
     * @param lpToken_ The address of the LP token associated with the pool
     * @notice This function checks if the deposit amount is valid, transfers the assets from the sender to this contract, approves the pool to spend the assets, updates relevant accounting data, and emits a `Deposit` event
     */
    function _depositMapleCash(uint256 amount_, address asset_, address pool_, address lpToken_) internal {
        uint256 lpTokens;
        uint256 sharesReceived;
        IERC20Helper(asset_).safeTransferFrom(msg.sender, address(this), amount_);
        IERC20Helper(asset_).safeIncreaseAllowance(pool_, amount_);

        totalAssetsReceived += amount_;
        uint256 balBefore = IPool(pool_).balanceOf(address(this));
        IPool(pool_).deposit(amount_, address(this));
        sharesReceived = IPool(pool_).balanceOf(address(this)) - balBefore;
        totalSharesReceived += sharesReceived;
        lpTokens = sharesReceived * 10 ** adjustedDecimals;
        totalLPTokensMinted += lpTokens;
        IERC20Helper(lpToken_).mint(nstblHub, lpTokens);
        emit Deposit(asset_, amount_, lpTokens, sharesReceived);
    }

    /**
     * @dev Internal function to request the redemption of LP tokens issued (lUSDC)
     * @param lpTokens_ The amount of LP tokens to redeem
     * @param asset_ The address of the asset to redeem
     * @param pool_ The address of the Maple Protocol pool
     * @notice This function checks if redemption is pending and if there are sufficient shares to redeem, records the escrowed shares, and emits a `RequestRedeem` event
     */
    function _requestRedeemMapleCash(uint256 lpTokens_, address asset_, address pool_) internal {
        require(!awaitingRedemption, "LM: Redemption Pending");
        require(IPool(pool_).balanceOf(address(this)) >= lpTokens_ / 10 ** adjustedDecimals, "LM: Insufficient Shares");
        escrowedMapleShares = IPool(pool_).requestRedeem(lpTokens_ / 10 ** adjustedDecimals, address(this));
        awaitingRedemption = true;
        emit RequestRedeem(asset_, lpTokens_, escrowedMapleShares);
    }

    /**
     * @dev Internal function to Redeem LP tokens issued (lUSDC)
     * @param asset_ The address of the asset to redeem
     * @param pool_ The address of the Maple Protocol pool
     * @param lpToken_ The address of the LP token associated with the pool
     * @param withdrawManager_ The address of the withdrawal manager contract
     * @notice This function redeems Maple Protocol tokens, burns the associated LP tokens, updates relevant accounting data, and emits a `Redeem` event
     */
    function _redeemMapleCash(address asset_, address pool_, address lpToken_, address withdrawManager_)
        internal
        returns (uint256)
    {
        uint256 exitCycleId = IWithdrawalManagerStorage(withdrawManager_).exitCycleId(address(this));
        (uint256 windowStart, uint256 windowEnd) = IWithdrawalManager(withdrawManager_).getWindowAtId(exitCycleId);
        uint256 _shares = escrowedMapleShares;

        require(block.timestamp >= windowStart && block.timestamp < windowEnd, "LM: Not in Window");

        uint256 stablesRedeemed = IPool(pool_).redeem(_shares, nstblHub, address(this));
        assetsRedeemed += stablesRedeemed;
        escrowedMapleShares = IWithdrawalManagerStorage(withdrawManager_).lockedShares(address(this));
        totalLPTokensBurned += (_shares - escrowedMapleShares) * 10 ** adjustedDecimals;
        IERC20Helper(lpToken_).burn(nstblHub, (_shares - escrowedMapleShares) * 10 ** adjustedDecimals);
        if (escrowedMapleShares == 0) {
            awaitingRedemption = false;
        }
        emit Redeem(asset_, _shares, stablesRedeemed);
        return stablesRedeemed;
    }

    /**
     * @dev Internal function to remove locked Maple Shares
     * @param asset_ The address of the asset to remove
     * @param pool_ The address of the Maple Protocol pool
     * @param withdrawManager_ The address of the withdrawal manager contract
     * @notice This function transfers locked Maple Shares from Maple Protocol to loanManager, updates relevant accounting data, and emits a `Remove` event
     */
    function _removeMapleCash(address asset_, address pool_, address withdrawManager_) internal {
        uint256 exitCycleId = IWithdrawalManagerStorage(withdrawManager_).exitCycleId(address(this));
        (, uint256 windowEnd) = IWithdrawalManager(withdrawManager_).getWindowAtId(exitCycleId);
        uint256 _shares = escrowedMapleShares;

        require(block.timestamp > windowEnd, "LM: Redemption Pending");

        uint256 sharesRemoved = IPool(pool_).removeShares(_shares, address(this));
        escrowedMapleShares -= sharesRemoved;

        if (escrowedMapleShares == 0) {
            awaitingRedemption = false;
        }

        emit Removed(asset_, _shares);
    }

    function _zeroAddressCheck(address address_) internal pure {
        require(address_ != address(0), "LM:INVALID_ADDRESS");
    }
}
