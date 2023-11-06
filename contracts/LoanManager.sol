// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {VersionedInitializable} from "./upgradeable/VersionedInitializable.sol";
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
 * @title LoanManager contract for managing Maple Protocol loans
 * @author Angad Singh Agarwal, Harshit Singhal
 * @notice This contract is intended to be used by NSTBL hub and future nealthy products
 * @dev This contract allows NSTBL hub to deposit assets into Maple Protocol pools, request and redeem Maple Protocol tokens, and perform various other loan management operations.
 */

contract LoanManager is LoanManagerStorage, VersionedInitializable {
    using SafeERC20 for IERC20Helper;
    using Address for address;

    uint256 internal constant REVISION = 1;
    uint256 private _locked;
    uint256 public versionSlot;

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier to ensure that only authorized callers can execute a function.
     */
    modifier authorizedCaller() {
        require(IACLManager(aclManager).authorizedCallersLoanManager(msg.sender), "Loan Manager: unAuth Hub");
        _;
    }

    /**
     * @dev Modifier to ensure that only the admin can execute a function.
     */
    modifier onlyAdmin() {
        require(msg.sender == IACLManager(aclManager).admin(), "LM: unAuth Admin");
        _;
    }

    /**
     * @dev Modifier to validate input parameters.
     */
    modifier validInput(uint256 _amount) {
        require(_amount > 0, "LM: Insufficient amount");
        _;
    }

    /**
     * @dev Modifier to prevent reentrancy attacks.
     */
    modifier nonReentrant() {
        require(_locked == 1, "LM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor to set immutables the LoanManager contract.
     */
    constructor() {
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;        
    }

    function initialize(address _nstblHub, address _aclManager, address _mapleUSDCPool) external initializer {
        nstblHub = _nstblHub;
        mapleUSDCPool = _mapleUSDCPool;
        aclManager = _aclManager;
        lUSDC = new TokenLP("Loan Manager USDC", "lUSDC", IACLManager(_aclManager).admin());
        adjustedDecimals = lUSDC.decimals() - IPool(mapleUSDCPool).decimals();
        _locked = 1;

        emit NSTBLHUBChanged(address(0), nstblHub);
    }

    /*//////////////////////////////////////////////////////////////
    LP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit assets into the Maple Protocol pool and mint LP tokens (lUSDC) to the NSTBL Hub.
     * @notice The LP tokens corresponding to the shares issued by the Maple Protocol pool are minted.
     * @param _amount The amount of the asset to deposit.
     */
    function deposit(uint256 _amount) external authorizedCaller nonReentrant {
        _depositMapleCash(_amount, usdc, mapleUSDCPool, address(lUSDC), MAPLE_POOL_MANAGER_USDC);
    }

    /**
     * @dev Request the redemption of LP tokens issued. (lUSDC)
     * @notice The shares corresponding to the LP tokens are requested for redemption from the Maple Protocol pool.
     * @param _lpTokens The amount of LP tokens to redeem.
     */
    function requestRedeem(uint256 _lpTokens)
        external
        authorizedCaller
        nonReentrant
        validInput(_lpTokens)
    { 
        _requestRedeemMapleCash(_lpTokens, usdc, mapleUSDCPool, address(lUSDC));
    }

    /**
     * @dev Redeem LP tokens issued. (lUSDC)
     * @notice The shares corresponding to the LP tokens that were requested for redemption are redeemed from the Maple Protocol pool.
     * @notice The shares are burned in the Maple Protocol pool contract and the LP tokens are burned here.
     */
    function redeem() external authorizedCaller nonReentrant {
        require(awaitingRedemption, "LM: No redemption requested");
        _redeemMapleCash(usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
    }

    /**
     * @dev Remove Locked Maple Shares (during request redemption).
     * @notice The shares corresponding to the LP tokens that were requested for redemption are removed from the Maple Protocol pool.
     * @notice The shares are transferred Maple Protocol's withdrawal manager contract back to Nealthy's loan Manager.
     */
    function remove() external authorizedCaller nonReentrant {
        require(awaitingRedemption, "LM: No Tokens to remove");
        _removeMapleCash(usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
    }

    /*//////////////////////////////////////////////////////////////
    INTERNALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to deposit assets into the Maple Protocol pool and mint LP tokens.
     * @param _amount The amount of the asset to deposit.
     * @param _asset The address of the asset being deposited.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @param _poolManager The address of the Maple Protocol pool manager contract.
     * @notice This function checks if the deposit amount is valid, transfers the assets from the sender to this contract, approves the pool to spend the assets, updates relevant accounting data, and emits a `Deposit` event.
     */
    function _depositMapleCash(uint256 _amount, address _asset, address _pool, address _lpToken, address _poolManager)
        internal
    {
        require(isValidDepositAmount(_amount, _pool, _poolManager), "LM: Invalid amount");
        uint256 lpTokens;
        uint256 sharesReceived;
        IERC20Helper(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Helper(_asset).safeIncreaseAllowance(_pool, _amount);

        totalAssetsReceived += _amount;
        uint256 balBefore = IPool(_pool).balanceOf(address(this));
        IPool(_pool).deposit(_amount, address(this));
        sharesReceived = IPool(_pool).balanceOf(address(this)) - balBefore;
        totalSharesReceived += sharesReceived;
        lpTokens = sharesReceived * 10 ** adjustedDecimals;
        totalLPTokensMinted += lpTokens;
        IERC20Helper(_lpToken).mint(nstblHub, lpTokens);
        emit Deposit(_asset, _amount, lpTokens, sharesReceived);
    }

    /**
     * @dev Internal function to request the redemption of LP tokens issued. (lUSDC)
     * @param _lpTokens The amount of LP tokens to redeem.
     * @param _asset The address of the asset to redeem.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @notice This function checks if redemption is pending and if there are sufficient shares to redeem, records the escrowed shares, and emits a `RequestRedeem` event.
     */
    function _requestRedeemMapleCash(uint256 _lpTokens, address _asset, address _pool, address _lpToken) internal {
        require(!awaitingRedemption, "LM: Redemption Pending");
        require(IPool(_pool).balanceOf(address(this)) >= _lpTokens / 10 ** adjustedDecimals, "LM: Insufficient Shares");
        escrowedMapleShares = IPool(_pool).requestRedeem(_lpTokens / 10 ** adjustedDecimals, address(this));
        awaitingRedemption = true;
        emit RequestRedeem(_asset, _lpTokens, escrowedMapleShares);
    }

    /**
     * @dev Internal function to Redeem LP tokens issued. (lUSDC)
     * @param _asset The address of the asset to redeem.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @param _withdrawManager The address of the withdrawal manager contract.
     * @notice This function redeems Maple Protocol tokens, burns the associated LP tokens, updates relevant accounting data, and emits a `Redeem` event.
     */
    function _redeemMapleCash(address _asset, address _pool, address _lpToken, address _withdrawManager) internal {
        uint256 exitCycleId = IWithdrawalManagerStorage(_withdrawManager).exitCycleId(address(this));
        (uint256 windowStart, uint256 windowEnd) = IWithdrawalManager(_withdrawManager).getWindowAtId(exitCycleId);
        uint256 _shares = escrowedMapleShares;

        require(block.timestamp >= windowStart && block.timestamp < windowEnd, "LM: Not in Window");

        uint256 stablesRedeemed = IPool(_pool).redeem(_shares, nstblHub, address(this));
        assetsRedeemed += stablesRedeemed;
        escrowedMapleShares = IWithdrawalManagerStorage(_withdrawManager).lockedShares(address(this));
        totalLPTokensBurned += (_shares - escrowedMapleShares) * 10 ** adjustedDecimals;
        IERC20Helper(_lpToken).burn(nstblHub, (_shares - escrowedMapleShares) * 10 ** adjustedDecimals);
        if (escrowedMapleShares == 0) {
            awaitingRedemption = false;
        }
        emit Redeem(_asset, _shares, assetsRedeemed);
    }

    /**
     * @dev Internal function to remove locked Maple Shares.
     * @param _asset The address of the asset to redeem.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @param _withdrawManager The address of the withdrawal manager contract.
     * @notice This function transfers locked Maple Shares from Maple Protocol to loanManager, updates relevant accounting data, and emits a `Remove` event.
     */
    function _removeMapleCash(address _asset, address _pool, address _lpToken, address _withdrawManager) internal {
        uint256 exitCycleId = IWithdrawalManagerStorage(_withdrawManager).exitCycleId(address(this));
        (uint256 windowStart,) = IWithdrawalManager(_withdrawManager).getWindowAtId(exitCycleId);
        uint256 _shares = escrowedMapleShares;

        require(block.timestamp > windowStart, "LM: Redemption Pending");

        uint256 sharesRemoved = IPool(_pool).removeShares(_shares, address(this));
        escrowedMapleShares -= sharesRemoved;

        if (escrowedMapleShares == 0) {
            awaitingRedemption = false;
        }

        emit Removed(_asset, _shares);
    }

    /*//////////////////////////////////////////////////////////////
    VIEWS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the number of LP tokens pending redemption for a specific LP token.
     * @return The number of LP tokens pending redemption, adjusted to the contract's decimals.
     */
    function getLpTokensPendingRedemption() external view returns (uint256) {
        return escrowedMapleShares * 10 ** adjustedDecimals;
    }

    /**
     * @dev Get the total assets represented by a given amount of LP tokens for a specific asset.
     * @param _lpTokens The amount of LP tokens to convert.
     * @return The total assets represented by the LP tokens, adjusted to the contract's decimals, or an error code if the asset is not supported.
     */
    function getAssets(uint256 _lpTokens) external view validInput(_lpTokens) returns (uint256) {

        return IPool(mapleUSDCPool).convertToAssets(_lpTokens / 10 ** adjustedDecimals);

    }

    /**
     * @dev Get the total assets with unrealized losses(from Maple Protocol's loans) represented by a given amount of LP tokens for a specific asset.
     * @param _lpTokens The amount of LP tokens to convert.
     * @return The total assets with unrealized losses represented by the LP tokens, adjusted to the contract's decimals, or an error code if the asset is not supported.
     */
    function getAssetsWithUnrealisedLosses(uint256 _lpTokens)
        external
        view
        validInput(_lpTokens)
        returns (uint256)
    {
        
        return IPool(mapleUSDCPool).convertToExitAssets(_lpTokens / 10 ** adjustedDecimals);
        
    }

    /**
     * @dev Get the number of shares (issued by Maple protocol pool to the Loan Manager) represented by a given amount of an asset.
     * @param _amount The amount of the asset to convert.
     * @return The number of shares represented by the amount of the asset, or an error code if the asset is not supported.
     */
    function getShares(uint256 _amount) external view validInput(_amount) returns (uint256) {
        
        return IPool(mapleUSDCPool).convertToShares(_amount);
        
    }

    /**
     * @dev Get the number of exit shares represented by a given amount of an asset.
     * @param _amount The amount of the asset to convert.
     * @return The number of exit shares represented by the amount of the asset, or an error code if the asset is not supported.
     */
    function getExitShares(uint256 _amount) external view validInput(_amount) returns (uint256) {
        
        return IPool(mapleUSDCPool).convertToExitShares(_amount);

    }

    /**
     * @dev Get the total unrealized losses (from Maple Protocol's loans) for a specific asset within the Maple Protocol pool.
     * @return The total unrealized losses for the asset, or an error code if the asset is not supported.
     */
    function getUnrealizedLossesMaple() external view returns (uint256) {

            return IPool(mapleUSDCPool).unrealizedLosses();

    }

    /**
     * @dev Get the total amount for a specific asset within the Maple Protocol pool.
     * @return The total amount for the asset, or an error code if the asset is not supported.
     */
    function getTotalAssetsMaple() external view returns (uint256) {

        return IPool(mapleUSDCPool).totalAssets();

    }

    /**
     * @dev Preview the redemption of assets based on the given asset and number of LP tokens.
     * @notice This function returns correct value only when a redemption has been requested and when called within the redemption window.
     * @param _lpTokens The number of LP tokens to be redeemed.
     * @return The previewed amount of redeemed assets, or an error code if the asset is not supported.
     */
    function previewRedeem(uint256 _lpTokens) external view returns (uint256) {
        
            return IPool(mapleUSDCPool).previewRedeem(_lpTokens / 10 ** 12);

    }

    /**
     * @dev Preview the deposit of assets based on the given asset and amount.
     * @param _amount The amount of assets to be deposited.
     * @return The previewed amount of shares that would be minted to the Loan Manager, or an error code if the asset is not supported.
     */
    function previewDepositAssets(uint256 _amount) external view returns (uint256) {
            return IPool(mapleUSDCPool).previewDeposit(_amount);
    }

    /**
     * @dev Check if a deposit amount is valid based on the liquidity cap and total assets in the Maple Protocol pool.
     * @param _amount The amount to deposit.
     * @param _pool The address of the Maple Protocol pool contract.
     * @param _poolManager The address of the Maple Protocol pool manager contract.
     * @return true if the deposit amount is valid; otherwise, false.
     */
    function isValidDepositAmount(uint256 _amount, address _pool, address _poolManager) public view returns (bool) {
        bytes memory val = _poolManager.functionStaticCall(abi.encodeWithSignature("liquidityCap()"));
        uint256 upperBound = uint256(bytes32(val));
        uint256 totalAssets = IPool(_pool).totalAssets();
        uint256 shares = IPool(_pool).previewDeposit(_amount);
        return (shares > 0) && (_amount < (upperBound - totalAssets)) ? true : false;
    }

    /*//////////////////////////////////////////////////////////////
    ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    function redeemManual(uint256 _shares) external onlyAdmin nonReentrant {
            _redeemMapleCashManual(_shares, usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
    }

    function _redeemMapleCashManual(uint256 _shares, address _asset, address _pool, address _lpToken, address _withdrawManager) internal {

        // uint256 _shares = escrowedMapleShares;

        uint256 stablesRedeemed = IPool(_pool).redeem(_shares, nstblHub, address(this));
        assetsRedeemed += stablesRedeemed;
        IERC20Helper(_lpToken).burn(nstblHub, (_shares) * 10 ** adjustedDecimals);
        emit Redeem(_asset, _shares, assetsRedeemed);
    }

    function getAirdroppedTokens(address _asset) external view returns(uint256 _value){
        _value = IERC20Helper(_asset).balanceOf(address(this));
    }

    function withdrawTokens(address _asset, uint256 _amount, address _destination) external authorizedCaller {
        IERC20Helper(_asset).safeTransfer(_destination, _amount);
    }

    function getMaturedAssets() external view returns(uint256 _value){
        _value = IPool(mapleUSDCPool).convertToAssets(IPool(mapleUSDCPool).balanceOf(address(this))) * 10**adjustedDecimals;
    }
    
    function getLPTotalSupply() external view returns(uint256 _value){
        _value = lUSDC.totalSupply();
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }

    function getVersion() public pure returns(uint256 _version) {
        _version = getRevision();
    }

    uint256[49] _gap;
}