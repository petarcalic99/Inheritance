// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// @ts-ignore next-line
import "forge-std/Test.sol";
import "../src/Inheritance.sol";

contract CounterTest is Test {
    Inheritance inheritance;
    address constant owner = address(1);
    address constant firstHeir = address(2);

    // Testing purposes
    event OwnerTimeUpdated();
    event NewOwner(address owner, address heir);

    receive() external payable {}

    function setUp() public {
        // sets the *next* call's msg.sender to be the input address
        vm.prank(owner);
        inheritance = new Inheritance(firstHeir);
    }

    function testHeirCorrectlyInit() public {
        address currentHeir = inheritance.heir();
        assertEq(currentHeir, firstHeir);
    }

    function testOwnerCorrectlyInit() public {
        address currentOwner = inheritance.owner();
        assertEq(currentOwner, owner);
    }

    function testWithdrawNotOwner() public {
        // sets the *next* call's msg.sender to be the input address
        vm.prank(firstHeir);

        // expect the next call to revert
        vm.expectRevert(bytes("Only owner is allowed"));

        // try to withdraw as non-owner
        inheritance.withdraw();
    }

    function testWithdrawByOwner0Balance() public {
        // sets the *next* call's msg.sender to be the owner
        vm.prank(owner);

        // expect the next call to emit an event
        vm.expectEmit(false, false, false, false);

        // emit the exact same event (same signture) to tell the framework
        // what it should look for
        emit OwnerTimeUpdated();

        // fire the function
        inheritance.withdraw();
    }

    function testWithdrawByOwnerWithBalance() public {
        // give 100 ether to the contract
        vm.deal(address(inheritance), 100);

        // test if the contract now own 100 ETHs
        assertEq(address(inheritance).balance, 100);

        // test if the owner doesn't have any ETH
        assertEq(owner.balance, 0);

        // sets the *next* call's msg.sender to be the owner
        vm.prank(owner);

        // fire the withdraw
        inheritance.withdraw();

        // test if the owner received the ETHs
        assertEq(owner.balance, 100);
    }

    function testBecomeOwner() public {
        // sets the *next* call's msg.sender to be the input address
        vm.prank(firstHeir);

        // expect the next call to revert
        vm.expectRevert(bytes("Owner can set the new heir after 30 days"));

        // try to withdraw as heir without waiting 30 days
        inheritance.becomeOwner(address(5));

        // sets the *next* call's msg.sender to be the input address
        vm.prank(address(4));

        // expect the next call to revert
        vm.expectRevert(bytes("Owner can set the new heir after 30 days"));

        // try to withdraw as random address
        inheritance.becomeOwner(address(5));

        // sets the *next* call's msg.sender to be the input address
        vm.prank(firstHeir);

        // increase the timestamp by 30 days
        vm.warp(1000 * 60 * 60 * 24 * 30);

        address newHeir = address(5);

        // expect the next call to emit an event
        vm.expectEmit(true, true, false, false);

        // emit the exact same event (same signture) to tell the framework
        // what it should look for
        emit NewOwner(firstHeir, newHeir);

        // try to withdraw as heir after waiting 30 days
        inheritance.becomeOwner(newHeir);

        // check that the new owner is the old heir
        assertEq(inheritance.owner(), firstHeir);
        // check that the new heir is address(5)
        assertEq(inheritance.heir(), newHeir);
    }
}