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
import {L2Gmx} from "../../../bridges/gmx/L2Contract.sol";


contract GmxBridgeUnitTest is Test {
    uint256 ethMainnet;
    uint256 arb;
    IArbitrumInbox public constant ARBITRUM_INBOX = IArbitrumInbox(0x6BEbC4925716945D46F0Ec336D5C2564F419682C);
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // USDC address for deposits
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant GMX_ROUTER = 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
    // goerli inbox
    // mainnet 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f
    // goerli = 0x6BEbC4925716945D46F0Ec336D5C2564F419682C
    address public constant ARBINBOX = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address public constant ARBSYS = 0x0000000000000000000000000000000000000064;
    address public constant ARBOUTBOX = 0x667e23ABd27E623c11d4CC00ca3EC4d0bD63337a;
    // address public constant L2GMX = 0xbbc18b580256a82dc0f9a86152b8b22e7c1c8005;

    AztecTypes.AztecAsset internal emptyAsset;

    // DefiBridgeProxy internal defiBridgeProxy;
    address private rollupProcessor;
    GmxBridge private bridge;

    function setUp() public {
        rollupProcessor = address(this);

        bridge = new GmxBridge(rollupProcessor, GMX_ROUTER, ARBINBOX, ARBSYS, ARBOUTBOX);
        vm.label(address(bridge), "GMX_BRIDGE");

        // create eth fork
        string memory MAINNET_RPC_URL = vm.envString('MAINNET_RPC_URL');
        ethMainnet = vm.createFork(MAINNET_RPC_URL);

        // create arbitrum fork
        string memory ARBITRUM_RPC_URL = vm.envString('ARBITRUM_RPC_URL');
        arb = vm.createFork(ARBITRUM_RPC_URL);
        // rollupProcessor.setBridgeGasLimit(address(bridge), 100000);
    }

    // TODO: change this function around to test empty assets
    function testErrorCodes() public {
       vm.expectRevert(ErrorLib.InvalidInputA.selector);
       bridge.convert(emptyAsset, emptyAsset, emptyAsset, emptyAsset, 0, 0, 0, address(0));
   }

   function testInvalidCaller(address _callerAddress) public {
        vm.assume(_callerAddress != rollupProcessor);
        // Use HEVM cheatcode to call from a different address than is address(this)
        vm.expectRevert(ErrorLib.InvalidCaller.selector);
        vm.prank(_callerAddress);
        bridge.convert(emptyAsset, emptyAsset, emptyAsset, emptyAsset, 0, 0, 0, address(0));
   }

   function testInboxL2Call() public {
        // deposit amount
        uint256 depositAmount = 2 ether;
        vm.deal(address(bridge), depositAmount * 5);
        uint256 inputValue = 5;

        AztecTypes.AztecAsset memory empty;
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

        uint256 ticketId = bridge.sendTxnToL2(depositAmount, inputAssetA.erc20Address,  inputAssetB.erc20Address, inputValue, true, 2000, 20000, 5000);
    }

    function testExampleBridge() public {
        // tests deploy to 0xb4c79dab8f259c7aee6e5b2aa729821864227e84
        uint256 depositAmount = 2 ether;
        vm.deal(address(bridge), depositAmount * 5);
        // Mint the depositAmount of Dai to rollupProcessor
        AztecTypes.AztecAsset memory empty;
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

        // Disabling linting errors here to show return variables
        // solhint-disable-next-line
        (uint256 outputValueA, uint256 outputValueB, bool isAsync) = bridge.convert{value: depositAmount}(
            inputAssetA,
            inputAssetB,
            outputAsset,
            empty,
            depositAmount,
            0,
            1,
            address(0)
        );
    }

    function testEndToEnd() public {
        // tests deploy to 0xb4c79dab8f259c7aee6e5b2aa729821864227e84
        vm.makePersistent(address(bridge));
        vm.selectFork(ethMainnet);
        uint256 depositAmount = 2 ether;
        vm.deal(address(bridge), depositAmount * 5);
        // Mint the depositAmount of Dai to rollupProcessor
        AztecTypes.AztecAsset memory empty;
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

        // Disabling linting errors here to show return variables
        // solhint-disable-next-line

        (uint256 outputValueA, uint256 outputValueB, bool isAsync) = bridge.convert{value: depositAmount}(
            inputAssetA,
            inputAssetB,
            outputAsset,
            empty,
            depositAmount,
            0,
            1,
            address(0)
        );

        // wait a few blocks



        // call finalize, push back to L1 Contract
    }

         // create eth fork
    //     string memory ARBITRUM_RPC_URL = vm.envString('ARBITRUM_RPC_URL');
    //     uint256 arbMainnet = vm.createFork(ARBITRUM_RPC_URL);

    //     vm.selectFork(arbMainnet);

    //     address[] memory _path;
    //     L2GMX.increasePosition{value: depositAmount}
    //     (
    //         _path,
    //         inputAssetA,
    //         0,
    //         1,
    //         10,
    //         true,
    //         1500,
    //         2,
    //         bytes32("0x"),
    //         address(this));
    // }

}
