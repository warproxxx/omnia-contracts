pragma solidity ^0.8.9;

interface IOracle {
    function getPrice(address _address) external view returns (uint256);  
}
