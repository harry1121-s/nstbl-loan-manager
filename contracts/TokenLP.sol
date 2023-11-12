// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenLP is ERC20 {
    address public loanManager;
    address public admin;

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event LoanManagerChanged(address indexed oldLoanManager, address indexed newLoanManager);

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(msg.sender == loanManager, "Token: LoanManager unAuth");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Token: Admin unAuth");
        _;
    }

    /*//////////////////////////////////////////////////////////////
    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, address admin_) ERC20(_name, _symbol) {
        require(admin_ != address(0), "LP: invalid Address");
        admin = admin_;
        loanManager = msg.sender;
        emit AdminChanged(address(0), admin);
        emit LoanManagerChanged(address(0), loanManager);
    }

    /*//////////////////////////////////////////////////////////////
    ACCOUNT MINT/BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address user_, uint256 amount_) external authorizedCaller {
        _mint(user_, amount_);
    }

    function burn(address user_, uint256 amount_) external authorizedCaller {
        _burn(user_, amount_);
    }

    /*//////////////////////////////////////////////////////////////
    OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    function setLoanManager(address loanManager_) external onlyAdmin {
        require(loanManager_ != address(0), "LP: invalid Address");
        address oldLoanManager = loanManager;
        loanManager = loanManager_;
        emit LoanManagerChanged(oldLoanManager, loanManager);
    }

    function setAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "LP: invalid Address");
        address oldAdmin = admin;
        admin = admin_;
        emit AdminChanged(oldAdmin, admin);
    }
}
