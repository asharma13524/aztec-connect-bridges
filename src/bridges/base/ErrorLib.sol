// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

library ErrorLib {
    error InvalidCaller();

    error InvalidInputA();
    error InvalidInputB();
    error InvalidOutputA();
    error InvalidOutputB();
    error InvalidInputAmount();
    error InvalidAuxData();

    error InvalidNonce();
    error AsyncDisabled();
}
