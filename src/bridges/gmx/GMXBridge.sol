// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {BridgeBase} from "../base/BridgeBase.sol";

contract GmxBridge is BridgeBase {
    error InvalidCaller();
    error AsyncModeDisabled();
    constructor(address _rollupProcessor) BridgeBase(_rollupProcessor) {
        
    }

    function convert(
        AztecTypes.AztecAsset memory _inputAssetA,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        AztecTypes.AztecAsset memory,
        uint256 _inputValue,
        uint256,
        uint64,
        address
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256 outputValueA,
            uint256,
            bool
        )
    {
        // ### INITIALIZATION AND SANITY CHECKS
        outputValueA = _inputValue;
        IERC20(_inputAssetA.erc20Address).approve(ROLLUP_PROCESSOR, _inputValue);
    }
}
