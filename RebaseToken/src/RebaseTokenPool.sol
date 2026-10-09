//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRebaseToken} from "./interfaces/IRebaseToken.sol"; // Adjust path if your interface is elsewhere
import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol"; // For CCIP structs

contract RebaseTokenPool is TokenPool {
    /**
     * The TokenPool base constructor requires:
     * @_token: The address of the rebase token this pool will manage.
     * @
     * @localTokenDecimals: The decimals of the token. Here, it's hardcoded to 18.
     * @
     * @_allowlist: An array of addresses permitted to send tokens through this pool.
     * @
     * @_rnmProxy: The address of the CCIP Risk Management Network (RMN) proxy.
     * @
     * @_router: The address of the CCIP router contract.
     */
    constructor(IERC20 _token, address[] memory _allowList, address i_rmnProxy, address _router)
        TokenPool(_token, _allowList, i_rmnProxy, _router)
    {
        //constructor body
    }

    // lockorburn function to process burning upon transfering
    function lockOrBurn(Pool.LockOrBurnInV1 calldata lockOrBurnIn)
        external
        override
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {
        _validateLockOrBurn(lockOrBurnIn);
        // Burn the tokens on the source chain. This returns their userAccumulatedInterest before the tokens were burned (in case all tokens were burned, we don't want to send 0 cross-chain)
        uint256 userInterestRate = IRebaseToken(address(i_token)).getUserInterestRate(lockOrBurnIn.originalSender);
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);
        // encode a function call to pass the caller's info to the destination pool and update it
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(userInterestRate)
        });
        // because of named return variable in the function signature : no explicit return statement is needed
    }

    // when tokens are beign receive on the chain where this RebaseTokenPool is deployed
    function releaseOrMint(Pool.ReleaseOrMintInV1 calldata releaseOrMintIn)
        external
        override
        returns (Pool.ReleaseOrMintOutV1 memory /* releaseOrMintOut */ )
    {
        // Named return optional
        _validateReleaseOrMint(releaseOrMintIn);
        // Decode the user interest rate sent from the source pool
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        // The receiver address is directly available
        address receiver = releaseOrMintIn.receiver;
        // Mint tokens to the receiver, applying the propagated interest rate
        IRebaseToken(address(i_token)).mint(
            receiver,
            releaseOrMintIn.amount,
            userInterestRate // Pass the interest rate to the rebase token's mint function
        );
        return Pool.ReleaseOrMintOutV1({destinationAmount: releaseOrMintIn.amount});
    }
}
