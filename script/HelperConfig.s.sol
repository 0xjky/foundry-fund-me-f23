// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@forge/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on local, deploy mock
    // Else grab exisiting address from live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        string chainName;
        address priceFeed; // ETH/USD pricefeed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory SepoliaConfig) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({chainName: "sepolia", priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getOrCreateAnvilConfig() public returns(NetworkConfig memory AnvilConfig) {
        // Don't want to redeploy mock if it already exists.
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Have to make a mock contract by deploying our own pricefeed
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed= new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({chainName: "local-anvil",priceFeed: address(mockPriceFeed)});

        return anvilConfig;

    }
}