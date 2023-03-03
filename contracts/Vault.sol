pragma solidity ^0.8.9;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { 
   VaultDetails
} from "./VaultLib.sol";

contract Vault is ERC1155, ReentrancyGuard {

    VaultDetails private VAULT_DETAILS;


    function initialize(VaultDetails memory _VAULT_DETAILS) external{
        VAULT_DETAILS = _VAULT_DETAILS;
    }
    

    function uri(uint256 id) public view override returns (string memory){
        return "";
    }

}