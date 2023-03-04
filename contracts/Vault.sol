pragma solidity ^0.8.9;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { IGMX } from "./interfaces/IGMX.sol";

import { VaultDetails, Whitelisted, Loan, GMXPosition } from "./VaultLib.sol";

import "hardhat/console.sol";

contract Vault is ERC1155, ReentrancyGuard {

    VaultDetails private VAULT_DETAILS;
    address[] public WHITELISTED_ASSETS;
    address public MAIN_ASSET;
    mapping(address => Whitelisted) private WHITELISTED_DETAILS;

    mapping(uint256 => Loan) public _loans;

    uint32 private constant LIQUIDITY_POSITION = 0;
    uint256 private _nextId = 1;

    uint256 public totalSupply = 0;

    event LiquidityAdded(address asset, uint256 amount, uint256 shares, address _lp);
    event LiquidtyRemoved(address asset, uint256 amount, uint256 shares, address _lp);
    event loanCreated(Loan loan_details, address borrower, uint256 loanId);

    function initialize(VaultDetails memory _VAULT_DETAILS, address[] memory _WHITELISTED_ASSETS,  Whitelisted[] memory _WHITELISTED_DETAILS) external{
        VAULT_DETAILS = _VAULT_DETAILS;
        WHITELISTED_ASSETS = _WHITELISTED_ASSETS;

        uint length = _WHITELISTED_ASSETS.length;
        uint32 max_exposure = 0;
        for (uint i=0; i< _WHITELISTED_ASSETS.length; i++) {
            WHITELISTED_DETAILS[_WHITELISTED_DETAILS[i].collection] = _WHITELISTED_DETAILS[i];


            if (_WHITELISTED_DETAILS[i].MAX_EXPOSURE > max_exposure){
                MAIN_ASSET = _WHITELISTED_ASSETS[i];
                max_exposure = _WHITELISTED_DETAILS[i].MAX_EXPOSURE;
            }

        }
    }

    function getUSDValue(address _asset, uint256 _amount) public view returns (uint256) {
        uint256 oraclePrice = IOracle(VAULT_DETAILS.ORACLE_CONTRACT).getPrice(_asset);
        return (_amount/10**3) * (oraclePrice / 10**15);
    }

    function getUSDBalance() public view returns (uint256){
        uint256 usd_balance = 0;

        for (uint i=0; i < WHITELISTED_ASSETS.length; i++ ) {
            //first check basic balance
            uint256 curr_balance = getUSDValue(WHITELISTED_ASSETS[i], IERC20(WHITELISTED_ASSETS[i]).balanceOf(address(this)));
            usd_balance = usd_balance + curr_balance;

            //now for hedges
            GMXPosition memory pos = IGMX(VAULT_DETAILS.GMX_CONTRACT).getPosition(msg.sender, MAIN_ASSET, WHITELISTED_ASSETS[i], false);

            if (pos.size > 0){
                uint256 posSize  = (pos.size/10**3) * (pos.averagePrice / 10**15);
                usd_balance = usd_balance + posSize;

                (bool hasProfit, uint256 delta) = IGMX(VAULT_DETAILS.GMX_CONTRACT).getDelta(WHITELISTED_ASSETS[i], pos.size, pos.averagePrice, false, pos.lastIncreasedTime);
                
                if (hasProfit){
                    usd_balance = usd_balance + delta;
                } else {
                    usd_balance = usd_balance - delta;
                }
            }
        }

        //now check active loans
        for (uint i=1; i <= _nextId; i++ ) {
            Loan memory curr_loan = _loans[i];

            if (curr_loan.timestamp != 0){
                usd_balance = usd_balance - getUSDValue(curr_loan.collateral, curr_loan.principal);
                uint256 duration_done = (block.timestamp - curr_loan.timestamp) * 10000 / (curr_loan.repaymentDate - curr_loan.timestamp);
                usd_balance = usd_balance + ((getUSDValue(curr_loan.loan_asset, curr_loan.repayment) * duration_done) / 10000);
            }
        }
        

        

         return usd_balance;
    }

    function hedgePositions() public {
        for (uint i=1; i <= _nextId; i++ ) {
            
            Loan memory curr_loan = _loans[i];

            if (curr_loan.timestamp != 0){

                uint256 collateral_value = getUSDValue(curr_loan.collateral, curr_loan.lockedAmount);
                uint256 loan_value = getUSDValue(curr_loan.loan_asset, curr_loan.repayment);

                console.log(collateral_value);
                console.log(loan_value);
                console.log("XX");

                if (collateral_value < loan_value && curr_loan.hedgeId == 0){
                    //open short position
                    uint256 collateralSize =  loan_value * 2;
                    IERC20(MAIN_ASSET).approve(VAULT_DETAILS.GMX_CONTRACT, collateralSize);
                    IERC20(MAIN_ASSET).transfer(VAULT_DETAILS.GMX_CONTRACT, collateralSize);

                    IGMX(VAULT_DETAILS.GMX_CONTRACT).increasePosition(msg.sender, MAIN_ASSET, curr_loan.loan_asset, loan_value, false);
                    uint256 hedgeId = uint256(keccak256(abi.encodePacked(msg.sender, MAIN_ASSET, curr_loan.loan_asset, false)));

                    _loans[i].hedgeId = hedgeId;
                    _loans[i].collateralSize = collateralSize;
                    _loans[i].hedgeSize = loan_value;

                    console.log("Opening a short");
                }


                if (curr_loan.hedgeId != 0 && collateral_value > loan_value){
                    //close short position
                    IGMX(VAULT_DETAILS.GMX_CONTRACT).decreasePosition(msg.sender, MAIN_ASSET, curr_loan.loan_asset, curr_loan.collateralSize,  curr_loan.hedgeSize, false, msg.sender);
                    _loans[i].hedgeId = 0;
                    _loans[i].collateralSize = 0;
                    _loans[i].hedgeSize = 0;
                    
                    console.log("Closing a short");
                }
            }
        }
    }

    function getBalanceIn(address _asset) public view returns (uint256) {
        uint256 price = IOracle(VAULT_DETAILS.ORACLE_CONTRACT).getPrice(_asset);
        return (getUSDBalance() * 1000 / price) / 1000;
    }

    function createLoan(address _collateral, address _loan_asset, uint256 _collateral_amount, uint256 _loan_amount, uint256 _repaymentDate) external nonReentrant returns (uint256 loanId) {
        require(IERC20(_collateral).balanceOf(address(msg.sender)) >= _collateral_amount, "Insufficient balance");
        require(IERC20(_loan_asset).balanceOf(address(this)) >= _loan_amount, "Insufficient balance");

        Whitelisted memory details = WHITELISTED_DETAILS[_collateral];

        uint256 collateral_worth = getUSDValue(_collateral, _collateral_amount);
        uint256 loanAmount_worth = getUSDValue(_loan_asset, _loan_amount);

        uint256 ltv = (loanAmount_worth * 1000)/(collateral_worth);
        uint apr = details.MIN_APR;
        
        if (ltv > 0){

            if (((details.slope * ltv) / 1000) > details.intercept){
                apr = Math.max(apr, ((details.slope * ltv) / 1000) - details.intercept);
            }

            
        }

        apr = Math.min(apr, details.MAX_APR);

        
        require(ltv < 950, "LTV Must be smaller than 95% for loans");

        uint256 repayment = _loan_amount + ((_loan_amount * apr * (_repaymentDate - block.timestamp))  / 31536000000);


        bool success = IERC20(_collateral).transferFrom(msg.sender, address(this), _collateral_amount);
        require(success, "UNSUCCESSFUL_TRANSFER");

        bool success2 = IERC20(_loan_asset).transfer(msg.sender, _loan_amount);
        require(success2, "UNSUCCESSFUL_TRANSFER");

        loanId = ++_nextId;
        _loans[loanId] = Loan({
            timestamp: block.timestamp,
            collateral: _collateral,
            loan_asset: _loan_asset,
            repaymentDate: _repaymentDate,
            principal: _loan_amount,
            repayment: repayment,
            lockedAmount: _collateral_amount,
            hedgeId: 0,
            collateralSize: 0,
            hedgeSize: 0
        });

        _mint(msg.sender, loanId, 1, "");
        emit loanCreated(_loans[loanId], msg.sender, loanId);
    }

    function repayLoan(uint32 _loanId) external {
        Loan storage curr_loan = _loans[_loanId];
        require(curr_loan.repaymentDate >= block.timestamp, "LOAN_EXPIRED");
        
        bool success = IERC20(curr_loan.loan_asset).transferFrom(msg.sender, address(this), curr_loan.repayment);  

        require(success, "UNSUCCESSFUL_TRANSFER");

        IERC20(curr_loan.collateral).transfer(msg.sender, curr_loan.lockedAmount);  

        delete _loans[_loanId];

        _burn(msg.sender, _loanId, 1);
    }

    function addLiquidity(uint256 _amount, address _asset)  external nonReentrant {
        require(WHITELISTED_DETAILS[_asset].lp_enabled == true, "Asset not whitelisted for liquidity provision");
        require(IERC20(_asset).balanceOf(address(msg.sender)) >= _amount, "Insufficient balance");

        uint256 shares = _amount;

        if (totalSupply > 0) {            
            shares =  _amount * (totalSupply / getUSDBalance());
        }

        bool success = IERC20(_asset).transferFrom(msg.sender, address(this), _amount);        
        if (success == false) {revert();}
        
        _mint(msg.sender, LIQUIDITY_POSITION, shares, "");

        emit LiquidityAdded(_asset, _amount, shares, msg.sender);
        totalSupply = totalSupply + shares;
    }

    function withdrawLiquidity(uint256 shares, address _asset) external nonReentrant {
        uint256 balance = this.balanceOf(msg.sender, LIQUIDITY_POSITION);

        if (balance < shares) {revert();}

        uint256 amount = shares * getUSDBalance() / totalSupply;
        if(IERC20(_asset).balanceOf(address(this)) < amount) {revert();}

        bool success = IERC20(_asset).transfer(msg.sender, amount);

        if (success){
            totalSupply = totalSupply - shares;
            _burn(msg.sender, LIQUIDITY_POSITION, shares);
            emit LiquidtyRemoved(_asset, amount, shares, msg.sender);
        }
    }
    

    function uri(uint256 id) public view override returns (string memory){
        return "";
    }

}