pragma solidity ^0.8.9;

import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "hardhat/console.sol";

import {VaultDetails} from './VaultLib.sol';


contract VaultManager {

    address private VAULT;
    address private ADMIN;
    address private ORACLE;

    address[] public vaults;
    mapping(address => bool) public validVault;


    constructor(address _VAULT, address _ORACLE, address _ADMIN){
        VAULT = _VAULT;
        ORACLE = _ORACLE;
        ADMIN = _ADMIN;
        validVault[_VAULT] = true;
    }


    function createVault(VaultDetails memory _VAULT_DETAILS, address[] memory _WHITELISTED_ASSETS,  Whitelisted[] memory _WHITELISTED_DETAILS, address _VAULT) public returns (address vault) {
        if (validVault[_VAULT] == true){
            vault = Clones.clone(VAULT);
            _VAULT_DETAILS.ORACLE_CONTRACT = ORACLE;
            IVault(vault).initialize(_VAULT_DETAILS, _WHITELISTED_ASSETS, _WHITELISTED_DETAILS);
            vaults.push(address(vault));
        }
    }

    function addValidVault(address _vault) public {
        require(msg.sender == ADMIN, "Only admin can add valid vault");
        validVault[_vault] = true;
    }

    


    function getVaults() public view returns (address[] memory) {
        return vaults;
    }
}