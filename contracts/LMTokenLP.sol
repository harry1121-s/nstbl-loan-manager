// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LMTokenLP is ERC20 {
    address public loanManager;
    address public admin;

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

    constructor(string memory _name, string memory _symbol, address _admin) ERC20(_name, _symbol) {
        admin = _admin;
        loanManager = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNT MINT/BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address _user, uint256 _amount) public authorizedCaller {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) public authorizedCaller {
        _burn(_user, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    function setLoanManager(address _loanManager) public onlyAdmin {
        loanManager = _loanManager;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }
}
