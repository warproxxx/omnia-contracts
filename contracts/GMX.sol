pragma solidity ^0.8.0;
import { IOracle } from "./interfaces/IOracle.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        

        Position memory pos = getPosition(_account, _collateralToken, _indexToken, _isLong);
        uint256 price = IOracle(ORACLE_CONTRACT).getPrice(_indexToken);

        if (pos.size == 0) {
            pos.averagePrice = price;
            pos.entryFundingRate = price;
            pos.lastIncreasedTime = block.timestamp;
        }

        pos.size = pos.size.add(_sizeDelta);
        pos.collateral = pos.collateral.add(_sizeDelta.mul(price).div(1e18));
        pos.lastIncreasedTime = block.timestamp;
        pos.averagePrice = pos.averagePrice.add(price.sub(pos.averagePrice).div(pos.size));

        positions[uint256(keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong)))] = pos;
    }

    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256) {
        
        Position memory pos = getPosition(_account, _collateralToken, _indexToken, _isLong);
        uint256 price = IOracle(ORACLE_CONTRACT).getPrice(_indexToken);

        if (pos.size == 0) {
            pos.averagePrice = price;
            pos.entryFundingRate = price;
            pos.lastIncreasedTime = block.timestamp;
        }

        pos.size = pos.size.sub(_sizeDelta);
        pos.collateral = pos.collateral.add(_sizeDelta.mul(price).div(1e18));
        pos.lastIncreasedTime = block.timestamp;
        pos.averagePrice = price; //its just a mock

        positions[uint256(keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong)))] = pos;

        //this should send profit to the user
        (bool hasProfit, uint256 delta) = getDelta(_indexToken, _sizeDelta, pos.averagePrice, _isLong, pos.lastIncreasedTime);
        
        uint256 sendAmount = _collateralDelta + _sizeDelta - delta;

        if (hasProfit){
            sendAmount = sendAmount + delta + delta;
        }

        IERC20(_collateralToken).transfer(_receiver, sendAmount);
    }

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) public view returns (Position memory _pos) {
        return positions[uint256(keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong)))];
    }
}