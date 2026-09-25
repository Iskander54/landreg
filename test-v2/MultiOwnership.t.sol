// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { MultiOwnership } from "../contracts-v2/MultiOwnership.sol";

/// @dev Proves the MultiOwnership remediations, above all H-03 (the seller gets paid).
contract MultiOwnershipTest is Test {
    MultiOwnership mo;
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");

    function setUp() public {
        mo = new MultiOwnership(seller); // seller starts at 100%
    }

    /// H-03 FIXED: buying a share pays the seller and moves ownership.
    function test_H03_buyShare_pays_seller() public {
        uint256 price = 2 ether;

        vm.prank(seller);
        uint256 index = mo.sellShare(40, price);

        vm.deal(buyer, price);
        vm.prank(buyer);
        mo.buyShare{ value: price }(index);

        // ownership moved
        assertEq(mo.ownershipPct(seller), 60);
        assertEq(mo.ownershipPct(buyer), 40);

        // H-03: the seller is credited the full price (pre-fix: this was 0, funds trapped)
        assertEq(mo.pendingWithdrawals(seller), price);
        assertEq(mo.salesCount(), 0);

        // seller can actually collect it
        vm.prank(seller);
        mo.withdraw();
        assertEq(seller.balance, price);
        assertEq(address(mo).balance, 0);
    }

    function test_buyShare_wrong_price_reverts() public {
        vm.prank(seller);
        mo.sellShare(10, 1 ether);
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        vm.expectRevert(bytes("MO: wrong price"));
        mo.buyShare{ value: 0.5 ether }(0);
    }

    /// M-03 FIXED: voting on a non-existent operation reverts (was silently accepted).
    function test_M03_vote_on_missing_operation_reverts() public {
        bytes32 op = keccak256("does-not-exist");
        vm.prank(seller);
        vm.expectRevert(bytes("MO: no such op"));
        mo.voteOperation(op);
    }

    function test_operation_propose_and_vote() public {
        bytes32 op = keccak256("sell-the-building");
        vm.prank(seller);
        mo.proposeOperation(op);
        vm.prank(seller);
        mo.voteOperation(op);
        assertEq(mo.operationVotes(op), 100); // seller holds 100%
    }
}
