pragma solidity ^0.8.0;
import { IOracle } from "./interfaces/IOracle.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract GMX {
    using SafeMath for uint256;

    mapping (uint256 => Position) public positions;
    address public ORACLE_CONTRACT;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    constructor(address _ORACLE_CONTRACT){
        ORACLE_CONTRACT = _ORACLE_CONTRACT;
    }

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) public view returns (bool, uint256) {
        
        uint256 price = IOracle(ORACLE_CONTRACT).getPrice(_indexToken);

        uint256 priceDelta = _averagePrice > price ? _averagePrice.sub(price) : price.sub(_averagePrice);
        uint256 delta = _size.mul(priceDelta).div(_averagePrice);

        bool hasProfit;

        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }

        return (hasProfit, delta);
    }

    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) public {

    }

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256) {
    
    }

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) public view returns (Position memory _pos) {
        return positions[uint256(keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong)))];
    }
}