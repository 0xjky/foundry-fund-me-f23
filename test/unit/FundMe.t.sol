// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "@forge/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// TEST
contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("USER");
    address USER_2 = makeAddr("USER_2");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();        
        _;
    }

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER_2, STARTING_BALANCE);
    }

    function testMinUSD() public {
        uint256 minUSD = 5;
        assertEq(fundMe.MINIMUM_USD(), minUSD);
    }

    function testOwner() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionAccuracy() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesDataStructures() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFunderIsAddedToArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder_1 = fundMe.getFunder(0);
        assertEq(funder_1, USER);

        vm.prank(USER_2);
        fundMe.fund{value: SEND_VALUE}();
        address funder_2 = fundMe.getFunder(1);
        assertEq(funder_2, USER_2); 

    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq((startingOwnerBalance + startingFundMeBalance), endingOwnerBalance);
    }

    function testWithdrawForMultipleFunders() public {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint160 numOfFunders = 10;
        uint160 startingIndexOfFunders = 1;

        // Loop to populate funders array with addresses with balance
        for (uint160 i = startingIndexOfFunders; i < numOfFunders; i++){
            hoax( address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
         }

        // Total funded
        uint totalFunded = (numOfFunders - startingIndexOfFunders) * SEND_VALUE;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        assert(address(fundMe).balance == 0);
        assertEq((startingOwnerBalance + totalFunded), fundMe.getOwner().balance);
    }
}

