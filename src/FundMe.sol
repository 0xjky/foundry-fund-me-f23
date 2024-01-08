// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToFunded;

    function fund() public payable {
        require(PriceConverter.getConversionRate(msg.value, s_priceFeed) >= MINIMUM_USD,"Didn't send enough ETH");
        s_funders.push(msg.sender);
        s_addressToFunded[msg.sender] += msg.value; // Add previous funded + just funded.
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0;funderIndex < fundersLength;funderIndex++) {
            address funder = s_funders[funderIndex]; // Find address of iteration in for loop
            s_addressToFunded[funder] = 0; // Reset Mapping
        }
        s_funders = new address[](0); // Reset the array
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");


    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0;funderIndex < s_funders.length;funderIndex++) {
            address funder = s_funders[funderIndex]; // Find address of iteration in for loop
            s_addressToFunded[funder] = 0; // Reset Mapping
        }
        s_funders = new address[](0); // Reset the array
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns(uint256) {
        return s_addressToFunded[fundingAddress];
    }

    function getFunder(uint256 i) external view returns (address) {
        return s_funders[i];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}
