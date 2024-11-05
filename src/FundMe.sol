//Get Funds from users
//withdraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256; // all uint256 will have access to the library funcs

    uint256 public constant MINIMUM_USD = 5e18;
    uint256 public myValue = 1;

    address[] public s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        //allow users to send $
        //have a minimum $ sent
        //1. How do we send ETH to this contract?

        /*myValue += 2; 
        require(msg.value > 1e18, "didn't send enough eth"); //1e18 = 1ETH = 1 * 10 ** 18 wei*/
        //what is a revert?
        //revert undo any actions that have been done, and send the remaining gas back

        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "minimum value should be 5$"); // msg.value is passed as an argument inside the getConversionRate function in the library
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public OnlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public OnlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        /* to withdraw funds there are three ways:
        transfer
        send
        call
        */

        /*payable(msg.sender).transfer(address(this).balance); //this keyword refers to the whole contract

        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");*/

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier OnlyOwner() {
        // require(msg.sender == i_owner, "Only owner can call this function");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; /*the underscore here says to execute the require line first then the rest of the func, 
            if it was declared above the require then the func will be executed first*/
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
