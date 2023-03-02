pragma solidity ^0.8.9;

import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import {VaultDetails} from './VaultLib.sol';


contract VaultManager {

    address private VAULT;
    address private ADMIN;
    address private ORACLE;

    address[] public vaults;



    constructor(address _VAULT, address _ORACLE, address _ADMIN){
        VAULT = _VAULT;
        ORACLE = _ORACLE;
        ADMIN = _ADMIN;
    }


    function createVault(VaultDetails memory _VAULT_DETAILS) public returns (address vault) {

        vault = Clones.clone(VAULT);
        IVault(vault).initialize(_VAULT_DETAILS);
        vaults.push(address(vault));
        
    }

    function isValidVault(address _VAULT_ADDRESS) public view returns (bool) {

        for (uint i; i < vaults.length; i++) {
            if (vaults[i] == _VAULT_ADDRESS)
                return true;
        }

        return false;
    }


    function getVaults() public view returns (address[] memory) {
        return vaults;
    }
}