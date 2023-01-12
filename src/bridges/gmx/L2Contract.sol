// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4;

import {IGmxRouter} from "src/interfaces/gmx/IRouter.sol";
import {IGmxVault} from "src/interfaces/gmx/IVault.sol";
import {IGmxPositionRouter} from "src/interfaces/gmx/IPositionRouter.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract L2Gmx {
    // TODO: May need to create a mapping to store users addrs and balances

    constructor () {}
    // GMX Router address for opening/closing position
    IGmxRouter public constant GMX_ROUTER = IGmxRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);

    // Vault for additional functionality, contains whitelisted tokens
    IGmxVault public constant GMX_VAULT = IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);

    // Gmx position router
    IGmxPositionRouter public constant GMX_POSITION_ROUTER = IGmxPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);

    // Arbsys contract
    IArbsys public constant ARBSYS = Arbsys(0x0000000000000000000000000000000000000064);


    function increasePosition(bytes memory data) public payable {
        // address _account;
        // address_collateralToken;
        // address _indexToken;
        // uint256 _sizeDelta;
        // bool _isLong;
        address[] memory _path;
        // approve position router
        GMX_ROUTER.approvePlugin(address(this));
        // decode info from aztec rollup contract on L1
        (address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) = abi.decode(data, (address, address , address, uint, bool));
        _path[0] = _collateralToken;
        // GMX_POSITION_ROUTER.createIncreasePosition{value: msg.value}(
        //     _path,
        //     _indexToken,
        //     _amountIn,
        //     _minOut,
        //     _sizeDelta,

        //     _isLong,
        //     _acceptablePrice,
        //     _executionFee,
        //     _referralCode,
        //     _callbackTarget);

        uint256 _executionFee = GMX_POSITION_ROUTER.minExecutionFee();
        GMX_POSITION_ROUTER.createIncreasePosition{value: msg.value}(
            _path,
            _indexToken,
            0,
            1,
            _sizeDelta,
            _isLong,
            1500,
            _executionFee,
            bytes32("0x"),
            address(this));

    }


    // Will need to wait ~ 7 days for fraud proof window here...
    function settleBackToL1(address destination, bytes calldata calldataForL1) external payable returns(uint) {
        ARBSYS.sendTxToL1()
    };

    // function decreasePosition(bytes memory data) public {
    //     // TODO: Need to figure out collateralDelta and receiver address
    //     (address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) = abi.decode(data, (address, address, address, uint256, uint, bool, address));
    //     GMX_POSITION_ROUTER.createDecreasePosition{value: msg.value}(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this));
    // }
    // Questions for later!!!
    // How is custody management going to work ???

    // (address sender, address indexAsset, address collateralAsset, uint256 sizeDelta, bool isLong) = abi.decode(data, (address, address, address, uint256, bool));

    // TODO: Add AddressAliasHelper
    modifier onlyFromMyL1Contract() override {
        require(AddressAliasHelper.undoL1ToL2Alias(msg.sender) == myL1ContractAddress, "ONLY_COUNTERPART_CONTRACT");
        _;
    }
}