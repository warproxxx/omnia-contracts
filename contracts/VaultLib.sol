pragma solidity ^0.8.9;

struct VaultDetails {
    string VAULT_NAME;
    string VAULT_DESCRIPTION;
    address ORACLE_CONTRACT;
}

struct Whitelisted{
    address collection;
    uint32 MAX_LTV;
    uint32 MAX_DURATION;
    uint32 MAX_APR;
    uint32 slope;
    bool lp_enabled;
}

struct Loan {
    uint256 timestamp;
    address collateral;
    uint256 repaymentDate;
    uint256 principal;
    uint256 repayment;    
}