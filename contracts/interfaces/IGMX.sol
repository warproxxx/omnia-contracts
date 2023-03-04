pragma solidity ^0.8.9;
import { GMXPosition } from "../VaultLib.sol";

interface IGMX {
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (GMXPosition memory);
    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);

}
