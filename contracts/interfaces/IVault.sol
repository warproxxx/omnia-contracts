pragma solidity ^0.8.9;

import { VaultDetails } from '../VaultLib.sol';

interface IVault {

    function initialize(
        VaultDetails memory _VAULT_DETAILS
    ) external;



}