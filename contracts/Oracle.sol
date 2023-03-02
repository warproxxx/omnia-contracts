pragma solidity ^0.8.9;
import "./interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";


contract Oracle {
    event OracleUpdate(address collection, uint256 value, uint256 timestamp);

    mapping (address => uint256) public prices;


    address public ADMIN;
    address public VAULUATION_PERFORMER;

    modifier onlyAdmin {
        require(msg.sender == ADMIN);
        _;
    }

    constructor(address _ADMIN, address _valuation_performer) {
        ADMIN = _ADMIN;
        VAULUATION_PERFORMER = _valuation_performer;
    }   

    function updatePrices(address[] calldata _addresses, uint256[] calldata _values) public onlyAdmin{
        //manual oracle is mostly just for testing

        require(_addresses.length == _values.length, "The length of two arrays must be same");

        for (uint i=0; i<_addresses.length; i++) {
            prices[_addresses[i]] = _values[i];
            emit OracleUpdate(_addresses[i], _values[i], block.timestamp);
        }
    }

    function getPrice(address _address, uint256 _id) public view returns (uint256) {

        AggregatorV3Interface priceFeed = AggregatorV3Interface(VAULUATION_PERFORMER);
        (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        if (answer != 0){
            return (uint256(answer));
        } else {
            return prices[_address];
        }
    }
}

