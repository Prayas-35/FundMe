//SPDX-License-Identifier: MIT

// 1. Deploy mock when we are in a local anvil chain
// 2. Keep track of contract address across different chais
// Sepolia ETH / USD Address
// Mainnet ETH / USD Address

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are in a local anvil chain, we will deploy a mock
    // otherwise, grab the address from the live network

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8; // DECIMAL IS UINT8
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address sepoliaEthUsdPriceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // price feed address

        if (activeNetworkConfig.sepoliaEthUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy a mock price feed
        // Return the address of the mock price feed
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            sepoliaEthUsdPriceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
