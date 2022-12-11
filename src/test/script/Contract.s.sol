// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import { GmxBridge } from "../../bridges/gmx/GMXBridge.sol";
import { L2Gmx } from "../../bridges/gmx/L2Contract.sol";

// https://github.com/makerdao/dss-bridge/pull/2/files (good deploy example to multiple networks)
contract MyScript is Script {
    function run() external {
        string memory MAINNET_RPC_URL = vm.envString('MAINNET_RPC_URL');
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);

        // deploy bridge contract on layer 1

        vm.selectFork(mainnetFork);

        vm.startBroadcast();

        GmxBridge bridge = new GmxBridge(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064, 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064, 0x6BEbC4925716945D46F0Ec336D5C2564F419682C,0x0000000000000000000000000000000000000064, 0x4c6f947Ae67F572afa4ae0730947DE7C874F95Ef);

        vm.stopBroadcast();

        // deploy arbitrum contract on layer 2

        string memory ARBITRUM_RPC_URL = vm.envString('ARBITRUM_RPC_URL');
        uint256 arbitrumMainnet = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumMainnet);

        vm.startBroadcast();

        L2Gmx l2contract = new L2Gmx();

        vm.stopBroadcast();

        // extra scripts for later
        // vm.waitForTransaction();
        // bridge.sendTxnToL2();
    }
}