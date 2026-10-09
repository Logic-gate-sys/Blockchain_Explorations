//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

contract LuxureToken {
    //errors
    error Danno_sour_NotEnoughFund(uint256, address);
    error Danno_sour_NotApproved(address, uint256);
    error Danno_sour_NoAllowance(address, address);

    //events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address holder => uint256 balance) user_to_balance;
    mapping(address => mapping(address => uint256)) private allowed; // allowed to use
    // name of token: optional
    uint256 private immutable i_totalSupply;

    //give all supply to the own at deployment
    constructor(uint256 _totalSupply) {
        i_totalSupply = _totalSupply;
        user_to_balance[msg.sender] = i_totalSupply;
    }

    function name() public view returns (string memory) {
        return "Luxure";
    }
    //token symbol :optional

    function symbol() public view returns (string memory) {
        return "LXR";
    }

    function totalSupply() public view returns (uint256) {
        return i_totalSupply;
    }

    // number of decimals the token uses
    function decimals() public view returns (uint8) {
        return 8; // example 8*1e8 = DAS 8
    }
    // total tokens in circulation

    // What's the amount of token a particular user owns
    function balanceOf(address _owner) public view returns (uint256 balance) {
        uint256 user_balance = user_to_balance[_owner];
        return user_balance;
    }
    //send tokens to someone

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // <--------
        if (user_to_balance[msg.sender] < _value) {
            revert Danno_sour_NotEnoughFund(user_to_balance[address(this)], msg.sender);
        }
        user_to_balance[msg.sender] -= _value;
        user_to_balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // transfer from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // is there enough fund for the owner to transfer
        if (user_to_balance[_from] < _value) {
            revert Danno_sour_NotEnoughFund(_value, _from);
        }
        //has the receiver gotten all their allowed share
        if (allowed[_from][msg.sender] < _value) {
            revert Danno_sour_NoAllowance(_from, _to);
        }
        // send
        user_to_balance[_from] -= _value;
        user_to_balance[_to] += _value;
        //decrease allowance
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // approve a user to spend  on your behalf
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // how much is spender still allowed to withraw from owner
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender]; // how much is left for the spender to spend of the amount they are allowed
    }
}
