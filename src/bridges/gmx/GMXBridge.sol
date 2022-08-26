// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {BridgeBase} from "../base/BridgeBase.sol";
import {IRollupProcessor} from "../../aztec/interfaces/IRollupProcessor.sol";

import {ErrorLib} from "../base/ErrorLib.sol";

import {IArbitrumInbox} from "src/interfaces/arbitrum/IInbox.sol";
import {IGmxRouter} from "src/interfaces/gmx/IRouter.sol";
import {IGmxVault} from "src/interfaces/gmx/IVault.sol";

import {IArbitrumOutbox} from "src/interfaces/arbitrum/IOutbox.sol";
import {ArbSys} from "src/interfaces/arbitrum/IArbSys.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

contract GmxBridge is BridgeBase {
    using SafeERC20 for IERC20;

    error InvalidCaller();
    error AsyncModeDisabled();

    // GMX Router address for opening/closing positions
    IGmxRouter public constant GMX_ROUTER = IGmxRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);

    // Vault for additional functionality, contains whitelisted tokens
    IGmxVault public constant GMX_VAULT = IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);

    // Arbitrum Inbox address for sending messages to Arbitrum L2
    IArbitrumInbox public constant ARBITRUM_INBOX = IArbitrumInbox(0x4c6f947Ae67F572afa4ae0730947DE7C874F95Ef);

    // Arbitrum Outbox Address for executing messages back on L1
    IArbitrumOutbox public constant ARBITRUM_OUTBOX = IArbitrumOutbox(0x4c6f947Ae67F572afa4ae0730947DE7C874F95Ef);

    // ArbSys Address for publishing messages on Arbitrum L2
    ArbSys public constant ARBSYS = ArbSys(0x0000000000000000000000000000000000000064);

    // USDC address for deposits
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;



    // test greeting string
    string greeting;

    constructor(
        address _rollupProcessor,
        address _gmxRouter,
        address _inbox,
        address _arbSys,
        address _outbox
    ) BridgeBase(_rollupProcessor) {}

    receive() external payable {}

    /**
     * @notice Set all the necessary approvals for all the latests vaults for the tokens supported by Yearn
     */
    function preApproveAll() external {
        uint256 numTokens = GMX_VAULT.whitelistedTokenCount();
        for (uint256 i; i < numTokens; ) {
            address token = GMX_VAULT.allWhitelistedTokens(i);
            _preApprove(address(GMX_ROUTER), token);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Perform all the necessary approvals for a given vault and its underlying.
     * @param _token - address of the token to approve
     */
    function _preApprove(address _gmxRouter, address _token) private {
        // Using safeApprove(...) instead of approve(...) here because underlying can be Tether;
        uint256 allowance = IERC20(_token).allowance(address(this), _gmxRouter);
        if (allowance != type(uint256).max) {
            // Resetting allowance to 0 in order to avoid issues with USDT
            IERC20(_token).safeApprove(_gmxRouter, 0);
            IERC20(_token).safeApprove(_gmxRouter, type(uint256).max);
        }

        allowance = IERC20(_token).allowance(address(this), ROLLUP_PROCESSOR);
        if (allowance != type(uint256).max) {
            // Resetting allowance to 0 in order to avoid issues with USDT
            IERC20(_token).safeApprove(ROLLUP_PROCESSOR, 0);
            IERC20(_token).safeApprove(ROLLUP_PROCESSOR, type(uint256).max);
        }

        IERC20(_gmxRouter).approve(ROLLUP_PROCESSOR, type(uint256).max);
    }


    function convert(
        AztecTypes.AztecAsset memory _inputAssetA,
        AztecTypes.AztecAsset memory _inputAssetB,
        AztecTypes.AztecAsset memory _outputAssetA,
        AztecTypes.AztecAsset memory,
        uint256 _inputValue,
        uint256 _interactionNonce,
        uint64 _auxData,
        address
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        )
    {
        // open position
        if (_auxData == 0) {
            // collateral provided in either USDC || ETH
            if (_inputAssetA.erc20Address != address(USDC) && _inputAssetA.assetType != AztecTypes.AztecAssetType.ETH){
                revert ErrorLib.InvalidInputA();
            }

            // operation in asynchronous
            isAsync = true;
            outputValueA = 0;
            outputValueB = 0;

            // inputAssetA == collateralToken (USDC || ETH)
            // multiple input assets, (collateralToken, indexToken, sizeDelta, isLong)

            // TODO: Figure out arbitrum node integration
            uint256 ticketId = sendTxnToL2(_inputAssetA.erc20Address, _inputAssetB.erc20Address, _inputValue, true, 2000, 20000, 5000);
        }
        // Approve Router Contract
        // Open/Increase Position
        // Close/Decrease Position
        return (outputValueA, outputValueB, isAsync);

        // ### INITIALIZATION AND SANITY CHECKS
        // outputValueA = _inputValue;
        // IERC20(_inputAssetA.erc20Address).approve(ROLLUP_PROCESSOR, _inputValue);
    }


    function sendTxnToL2 (address _collateralAsset, address _indexAsset, uint256 _sizeDelta, bool _isLong, uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid) public payable returns (uint256) {
        bytes memory callData = abi.encodeWithSignature("pluginIncreasePosition((address, address, address, uint256, bool))",
            address(this),
            _collateralAsset,
            _indexAsset,
            _sizeDelta,
            _isLong);
        console.log(_collateralAsset, "ca");
        console.log(_indexAsset, "ia");
        console.log(_sizeDelta, "sd");
        console.log(_isLong, "long");
        console.logBytes(callData);

        /*
        If the L2 account's balance (which now includes the DepositValue) is less than MaxSubmissionCost + Callvalue, the Retryable Ticket creation fails.
        If MaxSubmissionCost is less than the submission fee, the Retryable Ticket creation fails.
        */
        uint256 ticketId = ARBITRUM_INBOX.createRetryableTicket{ value: msg.value }(address(GMX_ROUTER), 0, 1000, msg.sender, msg.sender, 20000, 10000, callData);
        console.log("TICKET");

        return ticketId;
        // address destAddr,
        // uint256 arbTxCallValue,
        // uint256 maxSubmissionCost,
        // address submissionRefundAddress,
        // address valueRefundAddress,
        // uint256 maxGas,
        // uint256 gasPriceBid,
    }
}
