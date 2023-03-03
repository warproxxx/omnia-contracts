pragma solidity ^0.8.9;

import { VaultDetails, Whitelisted } from '../VaultLib.sol';

interface IVault {

    function initialize(VaultDetails memory _VAULT_DETAILS, address[] memory _WHITELISTED_ASSETS,  Whitelisted[] memory _WHITELISTED_DETAILS) external;

}