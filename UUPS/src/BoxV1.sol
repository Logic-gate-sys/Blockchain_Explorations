//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    constructor() {
        // do not allow constructor initialisation/reinitialisation
        _disableInitializers();
    }

    /**
     * @param newImplementation: new implementation to upgradet to
     * @notice specification of the new implementation to upgrade to and how
     */
    function _authorizeUpgrade(address newImplementation) internal override {}

    /**
     * @notice defining how our V1 should be initialised
    * caller of this function is the one authorised perform criticall functions relating to upgrades 
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function version() external pure returns (uint256) {
        return 1;
    }
}
