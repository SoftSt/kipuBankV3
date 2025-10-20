// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";

contract KipuBankV3Script is Script {
    address constant UNIVERSAL_ROUTER = 0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;
    address constant USDC = 0x65aFADD39029741B3b8f0756952C74678c9cEC93;
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    uint256 constant BANK_CAP_USD = 500_000e6;
    uint256 constant WITHDRAW_LIMIT_USD = 50_000e6;

    function run() external {
        vm.startBroadcast();

        KipuBankV3 bank = new KipuBankV3(
            UNIVERSAL_ROUTER,
            USDC,
            ETH_USD_FEED,
            BANK_CAP_USD,
            WITHDRAW_LIMIT_USD
        );

        console.log("KipuBankV3 deployed at:", address(bank));

        vm.stopBroadcast();
    }
}
