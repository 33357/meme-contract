// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import "../src/AVAXMEME.sol";

contract AVAXMEMETest is Test {
    AVAXMEME t;

    function setUp() public {
        t = new AVAXMEME();
        // vm.deal(address(this), 10 ether);
    }

    function testSet() public {
        assertEq(t.name(), "AVAXMEME");
        assertEq(t.symbol(), "AVME");
        assertEq(t.decimals(), 18);
        assertEq(t.deadline(), block.timestamp + 3 days);
        assertEq(t.refundTime(), t.deadline() + 1 hours);
        assertEq(t.targetAmount(), 1000 ether);
        assertEq(t.LPopen(), false);
    }

    function testReceive() public {
        uint256 beforeBalance = address(this).balance;
        payable(address(t)).call{value: 1 ether}("");
        assertEq(t.balanceOf(address(this)), 10000 ether);
        assertEq(address(t).balance, 1 ether);
        assertEq(beforeBalance - address(this).balance, 1 ether);

        vm.expectRevert("less than 1 AVAX");
        payable(address(t)).call{value: 0.9 ether}("");
        vm.expectRevert("greater than 100 AVAX");
        payable(address(t)).call{value: 101 ether}("");
        vm.expectRevert("reached limit of 100 AVAX");
        payable(address(t)).call{value: 100 ether}("");
        vm.warp(t.deadline());
        vm.expectRevert("deadline reached");
        payable(address(t)).call{value: 1 ether}("");
    }

    function testTransfer() public {
        payable(address(t)).call{value: 1 ether}("");
        vm.expectRevert("wait LP open");
        t.transfer(address(1), 1);
        vm.warp(t.deadline());
        vm.deal(address(t), 1000 ether);
        t.openLP();
        t.transfer(address(1), 1);
        assertEq(t.balanceOf(address(1)), 1);
    }

    function testRefund() public {
        uint256 beforeBalance = address(this).balance;
        payable(address(t)).call{value: 1 ether}("");
        vm.expectRevert("wait refundTime");
        t.refund();

        // vm.deal(address(t), 1000 ether);
        // t.openLP();
        // vm.expectRevert("LP opened");
        // t.refund();

        vm.warp(t.refundTime());
        t.refund();
        assertEq(t.balanceOf(address(this)), 0);
        assertEq(address(t).balance, 0);
        assertEq(beforeBalance, address(this).balance);

    }

    function testBatchRefund() public {
        uint256 beforeBalance = address(this).balance;
        payable(address(t)).call{value: 1 ether}("");
        vm.expectRevert("wait refundTime");
        address[] memory senderList = new address[](1);
        senderList[0] = address(this);
        t.batchRefund(senderList);
        vm.warp(t.refundTime());
        t.batchRefund(senderList);
        assertEq(t.balanceOf(address(this)), 0);
        assertEq(address(t).balance, 0);
        assertEq(beforeBalance, address(this).balance);
    }

    function testOpenLP() public {
        uint256 timestamp = block.timestamp;
        payable(address(t)).call{value: 1 ether}("");
        vm.expectRevert("wait deadline");
        t.openLP();
        vm.warp(t.deadline());
        vm.expectRevert("target not reached");
        t.openLP();
        vm.deal(address(t), 1000 ether);
        t.openLP();
        vm.expectRevert("LP opened");
        t.openLP();
    }

    receive() external payable {}
}
