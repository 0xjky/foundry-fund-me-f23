// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console} from "@forge/Script.sol";
import {DevOpsTools} from "@foundry-devops/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";


// Fund interaction

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        fundFundMe(mostRecentDeployment);
        vm.stopBroadcast();
    }

    function fundFundMe(address fundMeAddress) public {
        FundMe(payable(fundMeAddress)).fund{value: SEND_VALUE}();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

}

// Withdraw interaction

contract WithdrawFundMe is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        withdrawFundMe(mostRecentDeployment);
        vm.stopBroadcast();
    }

    function withdrawFundMe(address fundMeAddress) public {
        FundMe(fundMeAddress).withdraw();
        console.log("Withdrawn: %s", SEND_VALUE);
    }


}