// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Your Name/Alias
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease.
 * @notice Each user will have their own interest rate that is the global interest rate at the time of deposit.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    // error
    error RebaseToken_InterestRateCanOnlyDecrease(uint256 oldRate, uint256 newRate);

    uint256 private constant PRECISION_FACTOR = 1e18; // to represent 1 or 100%
    uint256 private s_interestRate = 5e10; // to represent 0.00000005 or 0.0000005%
    mapping(address user => uint256 lockedInterestRate) private s_userInterestRate; // locked interest rate for a user
    mapping(address user => uint256 lastUpdatedTimestamp) private s_userLastTimestamp; // time since user receives interest on their balance

    bytes32 public constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");

    //events
    event RebaseToken_InterestRateSet(uint256 newRate);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    /**
     * @notice Set the global interest rate for the contract.
     * @param _newInterestRate The new interest rate to set (scaled by PRECISION_FACTOR basis points per second).
     * @dev The interest rate can only decrease. Access control (e.g., onlyOwner) should be added.
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        // check new is less than old
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken_InterestRateCanOnlyDecrease(_newInterestRate, s_interestRate);
        }
        s_interestRate = _newInterestRate;
        emit RebaseToken_InterestRateSet(_newInterestRate);
    }

    /**
     *
     * @param _to :user address to be granted the role to mint and burn
     * @notice : only owner can grant such roles
     */
    function grandMintAndBurnRole(address _to) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _to);
    }

    /**
     * @notice Mints tokens to a user, typically upon deposit.
     * @dev Also mints accrued interest and locks in the current global rate for the user.
     * @param _to The address to mint tokens to.
     * @param _amount The principal amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        //mint accrue interest first
        _mintAccruedInterest(_to);
        //lock the current interest rate for user
        s_userInterestRate[_to] = s_interestRate;
        //mint with the standard mint function
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens, e.g., when they withdraw from a vault or for cross-chain transfers.
     * Handles burning the entire balance if _amount is type(uint256).max.
     * @param _from The user address from which to burn tokens.
     * @param _amount The amount of tokens to burn. Use type(uint256).max to burn all tokens.
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        // get current user balance
        uint256 currentBalance = balanceOf(_from);
        //make sure dust is prevented
        if (_amount == type(uint256).max) {
            _amount = currentBalance;
        }
        _mintAccruedInterest(_from);

        // burn
        _burn(_from, _amount);
    }

    /**
     *
     * @notice Transfers tokens from the caller to a recipient.
     * Accrued interest for both sender and recipient is minted before the transfer.
     * If the recipient is new, they inherit the sender's interest rate.
     * @param _to The address to transfer tokens to.
     * @param _amount The amount of tokens to transfer. Can be type(uint256).max to transfer full balance.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        //mint any accrue interest to both receipient and sender
        _mintAccruedInterest(_to);
        _mintAccruedInterest(msg.sender);
        // handle case where all balance is involved in transfer
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        //if receipient is new, they mush inherit interest rate
        if (balanceOf(_to) == 0 && _amount > 0) {
            s_userInterestRate[_to] = s_userInterestRate[msg.sender];
        }
        //internal transfer
        return super.transfer(_to, _amount);
    }

    /**
     *
     * @notice Transfers tokens from one address to another, on behalf of the sender,
     * provided an allowance is in place.
     * Accrued interest for both sender and recipient is minted before the transfer.
     * If the recipient is new, they inherit the sender's interest rate.
     * @param _sender The address to transfer tokens from.
     * @param _spender The address to transfer tokens to.
     * @param _amount The amount of tokens to transfer. Can be type(uint256).max to transfer full balance.
     * @return A boolean indicating whether the operation succeeded.
     */
    function transferFrom(address _sender, address _spender, uint256 _amount) public override returns (bool) {
        //mint any accrue interest to both receipient and sender
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_spender);
        // handle case where all balance is involved in transfer
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        //if receipient is new, they mush inherit interest rate
        if (balanceOf(_sender) == 0 && _amount > 0) {
            s_userInterestRate[_spender] = s_userInterestRate[_sender];
        }
        //internal transfer
        return super.transfer(_spender, _amount);
    }

    /**
     *
     * @param _account account of contract / user to be given acess to mint and burm
     */
    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account); // MINT_AND_BURN_ROLE is a bytes32 identifier
    }

    /**
     * @notice Returns the current balance of an account, including accrued interest.
     * @param _user The address of the account.
     * @return The total balance including interest.
     */
    function balanceOf(address _user) public view override returns (uint256) {
        uint256 principal_bal = super.balanceOf(_user); // token worth of balance
        // Calculate the growth factor based on accrued interest.
        uint256 growthFactor = _calculateUserAccumulatedInterestSinceLastUpdate(_user);
        // Apply the growth factor to the principal balance.
        return principal_bal * growthFactor / PRECISION_FACTOR;
    }

    //--------------- internal functions ---------------------------------------------------
    function _mintAccruedInterest(address _to) internal {
        //get user previous principal
        uint256 previous_principal = super.balanceOf(_to);
        //get current balance
        uint256 current_balance = balanceOf(_to);
        // get interest by the difference
        uint256 accruedInterest = current_balance - previous_principal;
        //update timestamp for usre
        s_userLastTimestamp[_to] = block.timestamp;
        //mint accrued interest if it's greater than 0
        if (accruedInterest > 0) {
            _mint(_to, accruedInterest);
        }
    }

    /**
     *
     * @dev Calculates the growth factor due to accumulated interest since the user's last update.
     * @param _user The address of the user.
     * @return  The growth factor, scaled by PRECISION_FACTOR. (e.g., 1.05x growth is 1.05 * 1e18)
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - s_userLastTimestamp[_user];
        if (timeElapsed == 0 || s_userInterestRate[_user] == 0) {
            return PRECISION_FACTOR;
        }

        uint256 fractionalInterest = s_userInterestRate[_user] * timeElapsed;
        // 3. The growth factor is (1 + fractional_interest_part).
        // Since '1' is represented as PRECISION_FACTOR, and fractionalInterest is already scaled, we add them.
        uint256 linearInterestFactor = PRECISION_FACTOR + fractionalInterest;
        return linearInterestFactor;
    }

    //------------- getters, views and pure functions ---------------------------------------

    /**
     * @notice Gets the principle balance of a user (tokens actually minted to them), excluding any accrued interest.
     * @param _user The address of the user.
     * @return The principle balance of the user.
     */
    function principalBalanceOf(address _user) public view returns (uint256) {
        return super.balanceOf(_user);
    }
    /**
     * @notice Gets the current global interest rate for the token.
     * @return The current global interest rate.
     */

    function getInterestRate() public view returns (uint256) {
        return s_interestRate;
    }

    //get user's interets rate
    function getUserInterestRate(address _user) external returns (uint256) {
        return s_userInterestRate[_user];
    }
}
