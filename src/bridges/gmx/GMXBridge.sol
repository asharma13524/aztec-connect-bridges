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

import {IGmxPositionRouter} from "src/interfaces/gmx/IPositionRouter.sol";

import {IArbitrumOutbox} from "src/interfaces/arbitrum/IOutbox.sol";
import {ArbSys} from "src/interfaces/arbitrum/IArbSys.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

import {L2Gmx} from "src/bridges/gmx/L2Contract.sol";

contract GmxBridge is BridgeBase {
    using SafeERC20 for IERC20;

    error InvalidCaller();
    error AsyncModeDisabled();

    L2Gmx public constant L2_CONTRACT = L2Gmx(0x67d269191c92Caf3cD7723F116c85e6E9bf55933);

    // GMX Router address for opening/closing positions
    IGmxRouter public constant GMX_ROUTER = IGmxRouter(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);

    // GMX PositionRouter to Manage Positions
    IGmxPositionRouter public constant GMX_POSITION_ROUTER = IGmxPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);

    // Vault for additional functionality, contains whitelisted tokens
    // IGmxVault public constant GMX_VAULT = IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);

    // Arbitrum Inbox address for sending messages to Arbitrum L2
    // mainnet 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f
    // goerli = 0x6BEbC4925716945D46F0Ec336D5C2564F419682C
    IArbitrumInbox public constant ARBITRUM_INBOX = IArbitrumInbox(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);

    // TODO: change addresses to rinkeby...
    // Arbitrum Outbox Address for executing messages back on L1
    IArbitrumOutbox public constant ARBITRUM_OUTBOX = IArbitrumOutbox(0x4c6f947Ae67F572afa4ae0730947DE7C874F95Ef);

    // // ArbSys Address for publishing messages on Arbitrum L2
    // ArbSys public constant ARBSYS = ArbSys(0x0000000000000000000000000000000000000064);

    // USDC address for deposits
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // test greeting string
    string greeting;

    constructor(
        address _rollupProcessor,
        address _gmxRouter,
        address _inbox,
        address _arbsys,
        address _outbox
    ) BridgeBase(_rollupProcessor) {}

    receive() external payable {}

    // /**
    //  * @notice Set all the necessary approvals for all the latests vaults for the tokens supported by Yearn
    //  */
    // function preApproveAll() external {
    //     uint256 numTokens = GMX_VAULT.whitelistedTokenCount();
    //     for (uint256 i; i < numTokens; ) {
    //         address token = GMX_VAULT.allWhitelistedTokens(i);
    //         _preApprove(address(GMX_ROUTER), token);
    //         unchecked {
    //             ++i;
    //         }
    //     }
    // }

    // /**
    //  * @notice Perform all the necessary approvals for a given vault and its underlying.
    //  * @param _token - address of the token to approve
    //  */
    // // function _preApprove(address _gmxRouter, address _token) private {
    // //     // Using safeApprove(...) instead of approve(...) here because underlying can be Tether;
    // //     uint256 allowance = IERC20(_token).allowance(address(this), _gmxRouter);
    // //     if (allowance != type(uint256).max) {
    // //         // Resetting allowance to 0 in order to avoid issues with USDT
    // //         IERC20(_token).safeApprove(_gmxRouter, 0);
    // //         IERC20(_token).safeApprove(_gmxRouter, type(uint256).max);
    // //     }

    // //     allowance = IERC20(_token).allowance(address(this), ROLLUP_PROCESSOR);
    // //     if (allowance != type(uint256).max) {
    // //         // Resetting allowance to 0 in order to avoid issues with USDT
    // //         IERC20(_token).safeApprove(ROLLUP_PROCESSOR, 0);
    // //         IERC20(_token).safeApprove(ROLLUP_PROCESSOR, type(uint256).max);
    // //     }

    // //     IERC20(_gmxRouter).approve(ROLLUP_PROCESSOR, type(uint256).max);
    // // }


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
        // long position
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

            // TODO: Figure out all the inputs and how they can come into the convert function (size delta ??)
            // TODO: Figure out how to set all the parameters in the createRetryableTicket function call
            // TODO: Figure out arbitrum node integration
            // TODO: Figure out gas costs
            // gasUsed = gasUsedL1 + gasUsedL2(not a field) so
            // gasPaid = gasUsed * effectiveGasPrice
            // gasPaidL1 = gasUsedL1 * effectiveGasPrice
            // gasPaidL2 = (gasUsed - gasUsedL1) * effectiveGasPrice

            uint256 ticketId = sendTxnToL2(msg.value, _inputAssetA.erc20Address, _inputAssetB.erc20Address, _inputValue, true, 2000, 20000, 5000);

        }
        // short position
        else if (_auxData == 1) {
             // collateral provided in either USDC || ETH
            if (_inputAssetA.erc20Address != address(USDC) && _inputAssetA.assetType != AztecTypes.AztecAssetType.ETH){
                revert ErrorLib.InvalidInputA();
            }

            // operation in asynchronous
            isAsync = true;
            outputValueA = 0;
            outputValueB = 0;

            // address[] memory _path, yes
            // address _indexToken, yes
            // uint256 _amountIn, yes
            // uint256 _minOut, needs to be sent across
            // uint256 _sizeDelta, needs to be sent across
            // bool _isLong, can determine via asset
            // uint256 _acceptablePrice,
            // uint256 _executionFee,
            // bytes32 _referralCode,
            // address _callbackTarget

            uint256 ticketId = sendTxnToL2(msg.value, _inputAssetA.erc20Address, _inputAssetB.erc20Address, _inputValue, false, 2000, 20000, 5000);
        }
        // Approve Router Contract
        // Open/Increase Position
        // Close/Decrease Position
        return (outputValueA, outputValueB, isAsync);

        // ### INITIALIZATION AND SANITY CHECKS
        // outputValueA = _inputValue;
        // IERC20(_inputAssetA.erc20Address).approve(ROLLUP_PROCESSOR, _inputValue);
    }

    //
    function redeemTxOnL2() public payable {
        // call to ArbRetryableTx.redeem(tx-id) in case of failure/unhappy case
        return;
    }

    function sendTxnToL2 (uint256 _depositAmount, address _collateralAsset, address _indexAsset, uint256 _sizeDelta, bool _isLong, uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid) public payable returns (uint256) {
        // TODO: use abi.encodeCall since it's safer (if possible), abi.encodeError also (type, typo safe, compiler will catch it)
        bytes memory callData = abi.encodeWithSignature("pluginIncreasePosition(address,address,address,uint256,bool)",
            address(this),
            _collateralAsset,
            _indexAsset,
            _sizeDelta,
            _isLong);
        /*
        If the L2 account's balance (which now includes the DepositValue) is less than MaxSubmissionCost + Callvalue, the Retryable Ticket creation fails.
        If MaxSubmissionCost is less than the submission fee, the Retryable Ticket creation fails.
        */
        // address(this) == 0xce71065d4017f316ec606fe4422e11eb2c47c246
        // TODO: change address(GMX_ROUTER) to address(L2_contract)
        uint256 ticketId = ARBITRUM_INBOX.createRetryableTicket{ value: _depositAmount }(address(L2_CONTRACT), 0, 1e18, msg.sender, msg.sender, 2e18, 0, callData);
        return ticketId;
        // address destAddr,
        // uint256 arbTxCallValue,
        // uint256 maxSubmissionCost,
        // address submissionRefundAddress,
        // address valueRefundAddress,
        // uint256 maxGas,
        // uint256 gasPriceBid,
    }

    /*
  @dev This function is called from the RollupProcessor.sol contract via the DefiBridgeProxy.
    It receives the aggreagte sum of all users funds for the input assets.
  @param AztecAsset inputAssetA a struct detailing the first input asset,
    this will always be set
  @param AztecAsset inputAssetB an optional struct detailing the second input asset,
    this is used for repaying borrows and should be virtual
  @param AztecAsset outputAssetA a struct detailing the first output asset,
    this will always be set
  @param AztecAsset outputAssetB a struct detailing an optional second output asset
  @param uint256 interactionNonce
  @param uint64 auxData other data to be passed into the bridge contract (slippage / nftID etc)
  @return uint256 outputValueA the return value of output asset A
  @return uint256 outputValueB optional return value of output asset B
  @dev this function should have a modifier on it to ensure
    it can only be called by the Rollup Contract
  */

  function canInteractionBeFinalised() public payable {
      // check if proof window has passed
      return;
  }


  /**
     * @dev Function to finalise an interaction
     * Converts the held amount of tranche asset for the given interaction into the output asset
     * @param interactionNonce The nonce value for the interaction that should be finalised
     */
    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 interactionNonce,
        uint64
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionCompleted
        )
    {

        // Merkle root is posted on L1 in the Outbox contract,
        // sendTxToL1 if fraud window has passed
        return (outputValueA, outputValueB, interactionCompleted);


    // has the fraud proof window passed ?
    // Arbsys.sendTxToL1()
    // call NodeInterface.lookupMessageBatchProof
    // call Outbox.executeTransaction
    }
}