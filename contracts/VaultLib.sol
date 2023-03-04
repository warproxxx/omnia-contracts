pragma solidity ^0.8.9;

struct VaultDetails {
    string VAULT_NAME;
    string VAULT_DESCRIPTION;
    address ORACLE_CONTRACT;
    address GMX_CONTRACT;
    uint32 MAX_LEVERAGE;
}

struct Delta {
    address collection;
    bool direction;
    uint256 delta;
}


struct Whitelisted{
    address collection;
    uint32 MAX_LTV;
    uint32 MAX_DURATION;
    uint32 MAX_APR;
    uint32 MIN_APR;
    uint32 slope;
    uint32 intercept;
    uint32 MAX_EXPOSURE; // max exposure to this collection as a % of portfolio
    uint32 HEDGE_AT; // the % change to hedge at
    uint32 MAX_DELTA_DIVERGENCE; //when a long or short is open, how much divergence is accepted before closing?
    uint32 HEDGE_PERCENTAGE; //how much % to hedge
    uint256 collateral_size;
}

struct Loan {
    uint256 timestamp;
    address collateral;
    address loan_asset;
    uint256 repaymentDate;
    uint256 principal;
    uint256 repayment;    
    uint256 lockedAmount;

}

struct GMXPosition {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }