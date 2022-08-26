// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {RollupProcessor} from "src/test/bridges/element/aztecmocks/RollupProcessor.sol";
import {AztecTypes} from "../../../aztec/libraries/AztecTypes.sol";
import {Test} from "forge-std/Test.sol";
import {IArbitrumInbox} from "src/interfaces/arbitrum/IInbox.sol";

// Example-specific imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GmxBridge} from "../../../bridges/gmx/GmxBridge.sol";
import {ErrorLib} from "../../../bridges/base/ErrorLib.sol";
import "forge-std/console.sol";


contract GmxBridgeUnitTest is Test {
    IArbitrumInbox public constant ARBITRUM_INBOX = IArbitrumInbox(0x4c6f947Ae67F572afa4ae0730947DE7C874F95Ef);
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // USDC address for deposits
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant GMX_ROUTER = 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
    address public constant ARBINBOX = 0x9685e7281Fb1507B6f141758d80B08752faF0c43;
    address public constant ARBSYS = 0x0000000000000000000000000000000000000064;
    address public constant ARBOUTBOX = 0x667e23ABd27E623c11d4CC00ca3EC4d0bD63337a;

    AztecTypes.AztecAsset internal emptyAsset;

    // DefiBridgeProxy internal defiBridgeProxy;
    address private rollupProcessor;
    GmxBridge private bridge;

    function setUp() public {
        rollupProcessor = address(this);

        bridge = new GmxBridge(rollupProcessor, GMX_ROUTER, ARBINBOX, ARBSYS, ARBOUTBOX);
        vm.label(address(bridge), "GMX_BRIDGE");
        vm.deal(address(bridge), 0);

        // rollupProcessor.setBridgeGasLimit(address(bridge), 100000);
    }

    function testErrorCodes() public {
        address callerAddress = address(bytes20(uint160(uint256(keccak256("non-rollup-processor-address")))));

        vm.prank(callerAddress);
        vm.expectRevert(ErrorLib.InvalidCaller.selector);
        bridge.convert(emptyAsset, emptyAsset, emptyAsset, emptyAsset, 0, 0, 0, address(0));
    }

    function testInvalidCaller(address _callerAddress) public {
        vm.assume(_callerAddress != rollupProcessor);
        // Use HEVM cheatcode to call from a different address than is address(this)
        vm.prank(_callerAddress);
        vm.expectRevert(ErrorLib.InvalidCaller.selector);
        bridge.convert(emptyAsset, emptyAsset, emptyAsset, emptyAsset, 0, 0, 0, address(0));
    }

    function testExampleBridge() public {
        uint256 depositAmount = 4;
        // Mint the depositAmount of Dai to rollupProcessor
        AztecTypes.AztecAsset memory empty;
        // TODO: Function reverting because not sending msg.value, do that now.
        // will have to bound

        AztecTypes.AztecAsset memory inputAssetA = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(USDC),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        AztecTypes.AztecAsset memory inputAssetB = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(DAI),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        AztecTypes.AztecAsset memory outputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(DAI),
            assetType: AztecTypes.AztecAssetType.ERC20
        });

    //     // Disabling linting errors here to show return variables
    //     // solhint-disable-next-line
        (uint256 outputValueA, uint256 outputValueB, bool isAsync) = bridge.convert{value: depositAmount}(
            inputAssetA,
            inputAssetB,
            outputAsset,
            empty,
            depositAmount,
            0,
            0,
            address(0)
        );
    }
}
