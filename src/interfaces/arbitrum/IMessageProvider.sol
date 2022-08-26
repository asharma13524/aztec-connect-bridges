// SPDX-License-Identifier: Apache-2.0
// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}