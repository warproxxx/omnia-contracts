pragma solidity ^0.8.9;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { VaultDetails, Whitelisted, Loan } from "./VaultLib.sol";

contract Vault is ERC1155, ReentrancyGuard {

    VaultDetails private VAULT_DETAILS;
    address[] public WHITELISTED_ASSETS;
    mapping(address => Whitelisted) private WHITELISTED_DETAILS;


    function initialize(VaultDetails memory _VAULT_DETAILS, address[] memory _WHITELISTED_ASSETS,  Whitelisted[] memory _WHITELISTED_DETAILS) external{
        VAULT_DETAILS = _VAULT_DETAILS;
        
        uint length = _WHITELISTED_ASSETS.length;
        
        for (uint i; i< length; ) {
            WHITELISTED_DETAILS[_WHITELISTED_DETAILS[i].collection] = _WHITELISTED_DETAILS[i];
            unchecked { ++i; }
        }
    }

    function createLoan(address _collateral, uint256 _loan_amount, uint32 _duration) external nonReentrant {
        // _mint(msg.sender, _LOAN_ID, _LOAN_AMOUNT, "");
    }
    

    function uri(uint256 id) public view override returns (string memory){
        return "";
    }

}