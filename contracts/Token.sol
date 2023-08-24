// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20{

    address public loanManager;

    modifier authorizedCaller{
        require(msg.sender == loanManager, "Loan Manager: unAuth");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _loanManager) ERC20(_name, _symbol){
       loanManager = msg.sender;
    }

    function mint(address _user, uint256 _amount)public authorizedCaller {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) public authorizedCaller {
        _burn(_user, _amount);
    }

}