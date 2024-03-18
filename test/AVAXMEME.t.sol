// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import "../src/AVAXMEME.sol";

contract AVAXMEMETest is Test {
    AVAXMEME t;

    function setUp() public {
        t = new AVAXMEME();
    }

    function testSet() public {
        assertEq(t.name(), "AVAXMEME");
        assertEq(t.symbol(), "AVME");
        assertEq(t.decimals(), 18);
        assertEq(t.deadline(), block.timestamp + 3 days);
        assertEq(t.minAVAX(), 1000);
        assertEq(t.LPopen(), false);
    }

    function testReceive() public {
        payable(address(t)).transfer(1 ether);
        assertEq(t.balanceOf(address(this)), 10000 ether);
    }

    function testTransfer() public {}

    function testRefund() public {}

    function testOpenLP() public {}
}
