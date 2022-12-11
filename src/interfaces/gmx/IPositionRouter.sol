// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IGmxPositionRouter {
    event Callback(address callbackTarget, bool success);
    event CancelDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event CancelIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event CreateDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 index,
        uint256 queueIndex,
        uint256 blockNumber,
        uint256 blockTime
    );
    event CreateIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 queueIndex,
        uint256 blockNumber,
        uint256 blockTime,
        uint256 gasPrice
    );
    event DecreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );
    event ExecuteDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event ExecuteIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );
    event IncreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );
    event SetAdmin(address admin);
    event SetCallbackGasLimit(uint256 callbackGasLimit);
    event SetDelayValues(
        uint256 minBlockDelayKeeper,
        uint256 minTimeDelayPublic,
        uint256 maxTimeDelay
    );
    event SetDepositFee(uint256 depositFee);
    event SetIncreasePositionBufferBps(uint256 increasePositionBufferBps);
    event SetIsLeverageEnabled(bool isLeverageEnabled);
    event SetMaxGlobalSizes(
        address[] tokens,
        uint256[] longSizes,
        uint256[] shortSizes
    );
    event SetMinExecutionFee(uint256 minExecutionFee);
    event SetPositionKeeper(address indexed account, bool isActive);
    event SetReferralStorage(address referralStorage);
    event SetRequestKeysStartValues(
        uint256 increasePositionRequestKeysStart,
        uint256 decreasePositionRequestKeysStart
    );
    event WithdrawFees(address token, address receiver, uint256 amount);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function admin() external view returns (address);

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external;

    function callbackGasLimit() external view returns (uint256);

    function cancelDecreasePosition(bytes32 _key, address _executionFeeReceiver)
        external
        returns (bool);

    function cancelIncreasePosition(bytes32 _key, address _executionFeeReceiver)
        external
        returns (bool);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function decreasePositionRequestKeys(uint256)
        external
        view
        returns (bytes32);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequests(bytes32)
        external
        view
        returns (
            address account,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            address receiver,
            uint256 acceptablePrice,
            uint256 minOut,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool withdrawETH,
            address callbackTarget
        );

    function decreasePositionsIndex(address) external view returns (uint256);

    function depositFee() external view returns (uint256);

    function executeDecreasePosition(
        bytes32 _key,
        address _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePositions(
        uint256 _endIndex,
        address _executionFeeReceiver
    ) external;

    function executeIncreasePosition(
        bytes32 _key,
        address _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePositions(
        uint256 _endIndex,
        address _executionFeeReceiver
    ) external;

    function feeReserves(address) external view returns (uint256);

    function getDecreasePositionRequestPath(bytes32 _key)
        external
        view
        returns (address[] memory);

    function getIncreasePositionRequestPath(bytes32 _key)
        external
        view
        returns (address[] memory);

    function getRequestKey(address _account, uint256 _index)
        external
        pure
        returns (bytes32);

    function getRequestQueueLengths()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function gov() external view returns (address);

    function increasePositionBufferBps() external view returns (uint256);

    function increasePositionRequestKeys(uint256)
        external
        view
        returns (bytes32);

    function increasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequests(bytes32)
        external
        view
        returns (
            address account,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong,
            uint256 acceptablePrice,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool hasCollateralInETH,
            address callbackTarget
        );

    function increasePositionsIndex(address) external view returns (uint256);

    function isLeverageEnabled() external view returns (bool);

    function isPositionKeeper(address) external view returns (bool);

    function maxGlobalLongSizes(address) external view returns (uint256);

    function maxGlobalShortSizes(address) external view returns (uint256);

    function maxTimeDelay() external view returns (uint256);

    function minBlockDelayKeeper() external view returns (uint256);

    function minExecutionFee() external view returns (uint256);

    function minTimeDelayPublic() external view returns (uint256);

    function referralStorage() external view returns (address);

    function router() external view returns (address);

    function sendValue(address _receiver, uint256 _amount) external;

    function setAdmin(address _admin) external;

    function setCallbackGasLimit(uint256 _callbackGasLimit) external;

    function setDelayValues(
        uint256 _minBlockDelayKeeper,
        uint256 _minTimeDelayPublic,
        uint256 _maxTimeDelay
    ) external;

    function setDepositFee(uint256 _depositFee) external;

    function setGov(address _gov) external;

    function setIncreasePositionBufferBps(uint256 _increasePositionBufferBps)
        external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGlobalSizes(
        address[] memory _tokens,
        uint256[] memory _longSizes,
        uint256[] memory _shortSizes
    ) external;

    function setMinExecutionFee(uint256 _minExecutionFee) external;

    function setPositionKeeper(address _account, bool _isActive) external;

    function setReferralStorage(address _referralStorage) external;

    function setRequestKeysStartValues(
        uint256 _increasePositionRequestKeysStart,
        uint256 _decreasePositionRequestKeysStart
    ) external;

    function shortsTracker() external view returns (address);

    function vault() external view returns (address);

    function weth() external view returns (address);

    function withdrawFees(address _token, address _receiver) external;

}