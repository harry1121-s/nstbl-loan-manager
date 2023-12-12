// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@nstbl-acl-manager/contracts/IACLManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenLP is ERC20 {
    /*//////////////////////////////////////////////////////////////
    Storage
    //////////////////////////////////////////////////////////////*/

    address public loanManager;
    address public aclManager;

    /*//////////////////////////////////////////////////////////////
    Events
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when the address of LoanManager is updated
     * @param oldLoanManager_ The old address of the LoanManager
     * @param newLoanManager_ The updated address of the LoanManager
     */
    event LoanManagerChanged(address indexed oldLoanManager_, address indexed newLoanManager_);

    /*//////////////////////////////////////////////////////////////
    Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(msg.sender == loanManager, "Token: LoanManager unAuth");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == IACLManager(aclManager).admin(), "Token: Admin unAuth");
        _;
    }

    /*//////////////////////////////////////////////////////////////
    Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_, address aclManager_) ERC20(name_, symbol_) {
        require(aclManager_ != address(0), "Token: invalid Address");
        aclManager = aclManager_;
        loanManager = msg.sender;
        emit LoanManagerChanged(address(0), loanManager);
    }

    /*//////////////////////////////////////////////////////////////
    Externals - accounting
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint tokens to the user
     * @dev Only the LoanManager can call this function
     * @param user_ The address of the user
     * @param amount_ The amount of tokens to mint
     */
    function mint(address user_, uint256 amount_) external authorizedCaller {
        _mint(user_, amount_);
    }

    /**
     * @notice Burn tokens from the user
     * @dev Only the LoanManager can call this function
     * @param user_ The address of the user
     * @param amount_ The amount of tokens to burn
     */
    function burn(address user_, uint256 amount_) external authorizedCaller {
        _burn(user_, amount_);
    }

    /*//////////////////////////////////////////////////////////////
    Externals - setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the address of the LoanManager
     * @dev Only the admin can call this function
     * @param loanManager_ The address of the LoanManager
     */
    function setLoanManager(address loanManager_) external onlyAdmin {
        require(loanManager_ != address(0), "Token: invalid Address");
        address oldLoanManager = loanManager;
        loanManager = loanManager_;
        emit LoanManagerChanged(oldLoanManager, loanManager);
    }
}
