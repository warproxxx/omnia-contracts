pragma solidity ^0.8.9;
import "./interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";


contract Oracle {
    event OracleUpdate(address collection, uint256 value, uint256 timestamp);

    mapping (address => uint256) public prices;
    mapping (address => address) public aggregators;


    address public ADMIN;

    modifier onlyAdmin {
        require(msg.sender == ADMIN);
        _;
    }

    constructor(address _ADMIN) {
        ADMIN = _ADMIN  ;
    }   

    function setAggregators(address[] calldata _addresses, address[] calldata _aggregators) public onlyAdmin{
        require(_addresses.length == _aggregators.length, "The length of two arrays must be same");

        for (uint i=0; i<_addresses.length; i++) {
            aggregators[_addresses[i]] = _aggregators[i];
        }
    }

    function updatePrices(address[] calldata _addresses, uint256[] calldata _values) public onlyAdmin{
        //manual oracle is mostly just for testing

        require(_addresses.length == _values.length, "The length of two arrays must be same");

        for (uint i=0; i<_addresses.length; i++) {
            prices[_addresses[i]] = _values[i];
            emit OracleUpdate(_addresses[i], _values[i], block.timestamp);
        }
    }

    function getPrice(address _address) public view returns (uint256) {

        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregators[_address]);
        (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        if (answer != 0){
            return (uint256(answer));
        } else {
            return prices[_address];
        }
    }
}

