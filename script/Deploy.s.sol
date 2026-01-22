// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FluxToken.sol";
import "../src/FluxEthPool.sol";
import "../src/SimpleRouter.sol";

contract Deploy is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        address eth = vm.envAddress("WETH"); 
        vm.startBroadcast(key);
        FluxToken flux = new FluxToken();
        FluxEthPool pool = new FluxEthPool(eth,address(flux));
        SimpleRouter router = new SimpleRouter(eth,address(flux),address(pool));

        console.log("Flux Address:",address(flux));
        console.log("Pool Address:",address(pool));
        console.log("Router Address:",address(router));
        vm.stopBroadcast();
    }
}