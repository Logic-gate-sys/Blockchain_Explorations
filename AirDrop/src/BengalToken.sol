//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {ERC20} from "../lib/openzepplin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzepplin-contracts/contracts/access/Ownable.sol";

contract BengalToken is ERC20, Ownable {
    constructor() ERC20("Bagel", "BAGEL") Ownable() {
        // The initial supply will be managed by the owner minting tokens as needed,
        // rather than minting a fixed supply at deployment.
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
