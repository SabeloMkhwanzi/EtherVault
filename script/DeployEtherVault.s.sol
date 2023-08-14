// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {EtherVault} from "../src/EtherVault.sol";

contract DeployEtherVault is Script {
    function run() external returns (EtherVault, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        EtherVault etherVault = new EtherVault(priceFeed);
        vm.stopBroadcast();

        return (etherVault, helperConfig);
    }
}
