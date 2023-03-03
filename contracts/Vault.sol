pragma solidity ^0.8.9;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IOracle } from "./interfaces/IOracle.sol";

import { VaultDetails, Whitelisted, Loan } from "./VaultLib.sol";

import "hardhat/console.sol";

contract Vault is ERC1155, ReentrancyGuard {

    VaultDetails private VAULT_DETAILS;
    address[] public WHITELISTED_ASSETS;
    mapping(address => Whitelisted) private WHITELISTED_DETAILS;

    mapping(uint256 => Loan) public _loans;

    uint32 private constant LIQUIDITY_POSITION = 0;
    uint256 private _nextId = 1;

    uint256 public totalSupply = 0;


    function initialize(VaultDetails memory _VAULT_DETAILS, address[] memory _WHITELISTED_ASSETS,  Whitelisted[] memory _WHITELISTED_DETAILS) external{
        VAULT_DETAILS = _VAULT_DETAILS;
        
        uint length = _WHITELISTED_ASSETS.length;
        
        for (uint i; i< length; ) {
            WHITELISTED_DETAILS[_WHITELISTED_DETAILS[i].collection] = _WHITELISTED_DETAILS[i];
            unchecked { ++i; }
        }
    }

    function createLoan(address _collateral, uint256 _loan_amount, uint32 _duration) external nonReentrant {
        Whitelisted memory details = WHITELISTED_DETAILS[_collateral];
        uint apr = details.MAX_APR - (_duration / 100) * details.slope;


        // _mint(msg.sender, _LOAN_ID, _LOAN_AMOUNT, "");
    }

    function getUSDBalance() public view returns (uint256){
        uint256 usd_balance = 0;

        for (uint i; i < WHITELISTED_ASSETS.length; ) {
            uint256 curr_balance = IERC20(WHITELISTED_ASSETS[i]).balanceOf(address(this)) * IOracle(VAULT_DETAILS.ORACLE_CONTRACT).getPrice(WHITELISTED_ASSETS[i]);
            usd_balance = usd_balance + curr_balance;
            unchecked { ++i; }
        }

        //loop thru loans and hedges too

         return usd_balance;
    }

    function getBalanceIn(address _asset) public view returns (uint256) {
        uint256 price = IOracle(VAULT_DETAILS.ORACLE_CONTRACT).getPrice(_asset);
        return (getUSDBalance() * 1000 / price) / 1000;
    }

    

    function addLiquidity(uint256 _amount, address _asset)  external nonReentrant {
        require(WHITELISTED_DETAILS[_asset].lp_enabled == true, "Asset not whitelisted for liquidity provision");
        require(IERC20(_asset).balanceOf(address(msg.sender)) >= _amount, "Insufficient balance");

        uint256 shares = _amount;

        if (totalSupply > 0) {
            shares =  _amount * (totalSupply / getBalanceIn(_asset));
        }

        bool success = IERC20(_asset).transferFrom(msg.sender, address(this), _amount);        
        if (success == false) {revert();}

        _mint(msg.sender, LIQUIDITY_POSITION, shares, "");
        totalSupply = totalSupply + shares;
    }

    function withdrawLiquidity(uint256 shares, address _asset) external nonReentrant {
        uint256 balance = this.balanceOf(msg.sender, LIQUIDITY_POSITION);

        if (balance < shares) {revert();}

        uint256 amount = shares * getBalanceIn(_asset) / totalSupply;
        if(IERC20(_asset).balanceOf(address(this)) < amount) {revert();}

        bool success = IERC20(_asset).transfer(msg.sender, amount);

        if (success){
            totalSupply = totalSupply - shares;
            _burn(msg.sender, LIQUIDITY_POSITION, shares);
        }

    }
    

    function uri(uint256 id) public view override returns (string memory){
        return "";
    }

}