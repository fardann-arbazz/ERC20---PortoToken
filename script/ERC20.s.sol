// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {PortoToken} from "../src/ERC20.sol";

contract PortoTokenScript is Script {
    function run() external returns (PortoToken token) {
        vm.startBroadcast();

        token = new PortoToken();

        vm.stopBroadcast();
    }
}
