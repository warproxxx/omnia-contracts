pragma solidity ^0.8.9;

struct VaultDetails {
    string VAULT_NAME;
    string VAULT_DESCRIPTION;
    address ORACLE_CONTRACT;
    address GMX_CONTRACT;
    uint32 MAX_LEVERAGE;

}

struct Whitelisted{
    address collection;
    uint32 MAX_LTV;
    uint32 MAX_DURATION;
    uint32 MAX_APR;
    uint32 MIN_APR;
    uint32 slope;
    uint32 intercept;
    uint32 MAX_EXPOSURE;
    bool lp_enabled;
}

struct Loan {
    uint256 timestamp;
    address collateral;
    address loan_asset;
    uint256 repaymentDate;
    uint256 principal;
    uint256 repayment;    
    uint256 lockedAmount;
    uint256 hedgeId;
    uint256 collateralSize;
    uint256 hedgeSize;

}
