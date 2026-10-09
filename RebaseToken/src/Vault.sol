// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol"; // Added later, shown for context

contract Vault {
    IRebaseToken private immutable i_rebaseToken;
    //error
    // error Vault_RedeemFail(address indexed user, uint256 indexed amount);

    error Vault_NotEthSent();
    error Vault_TransferFailed();
    //custome events

    event Vault_EthDeposited(address indexed user, uint256 indexed amount);
    event Vault_EthRedeemed(address indexed user, uint256 indexed amount);

    // set the address of i_rebase token on runtme
    constructor(IRebaseToken _address) {
        i_rebaseToken = _address;
    }

    /**
     * @notice eposite is the main way users interact with our contract
     */
    function deposite() public payable {
        // amount to be deposited
        uint256 amountToDeposite = msg.value;
        if (amountToDeposite == 0) {
            revert Vault_NotEthSent();
        }
        // get interest rete
        uint256 interestRate = i_rebaseToken.getUserInterestRate(msg.sender);
        //  give mint
        i_rebaseToken.mint(msg.sender, amountToDeposite, interestRate);

        emit Vault_EthDeposited(msg.sender, amountToDeposite);
    }

    /**
     * @notice Allows a user to burn their RebaseTokens and receive a corresponding amount of ETH.
     * @param _amount The amount of RebaseTokens to redeem.
     * @dev Follows Checks-Effects-Interactions pattern. Uses low-level .call for ETH transfer.
     */
    function redeem(uint256 _amount) public {
        // burn token amount to be redeemed
        i_rebaseToken.burn(msg.sender, _amount);
        //transfer token to user
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault_TransferFailed();
        }
        // emit event
        emit Vault_EthRedeemed(msg.sender, _amount);
    }
    // ------------ receiver ------------------
    /**
     * @notice if Eth is sent to the contract without function call
     */

    receive() external payable {} // when raw Eth is sent to the contract

    /**
     * @notice : get address of rebase token
     */
    function getRebaseTokenAddress() public view returns (address) {
        return address(i_rebaseToken);
    }
}
