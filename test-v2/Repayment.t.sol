// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Repayment} from "../contracts-v2/Repayment.sol";

/// @dev Proves the Repayment remediations, above all M-03 (surplus refund is now conditional).
contract RepaymentTest is Test {
    Repayment rep;
    address creditor = makeAddr("creditor");
    address creditee = makeAddr("creditee");

    uint256 constant PRINCIPAL = 10 ether;
    uint256 constant RATE = 10; // 10% per period

    function setUp() public {
        rep = new Repayment(creditor, creditee, PRINCIPAL, RATE);
    }

    /// M-03 FIXED: overpaying past the full balance refunds exactly the surplus.
    function test_M03_overpayment_refunds_surplus() public {
        uint256 interest = rep.interestDue(); // 1 ether
        uint256 surplus = 0.5 ether;
        uint256 pay = interest + PRINCIPAL + surplus; // clears the loan and overshoots

        vm.deal(creditee, pay);
        vm.prank(creditee);
        rep.makePayment{value: pay}();

        assertEq(rep.balance(), 0);                    // loan cleared
        assertEq(creditee.balance, surplus);           // exactly the surplus came back
        assertEq(rep.creditorWithdrawable(), interest + PRINCIPAL); // creditor keeps the rest
    }

    /// Exact payment (interest only) leaves the balance and refunds nothing.
    function test_interest_only_no_refund() public {
        uint256 interest = rep.interestDue();
        vm.deal(creditee, interest);
        vm.prank(creditee);
        rep.makePayment{value: interest}();

        assertEq(rep.balance(), PRINCIPAL);
        assertEq(creditee.balance, 0);
        assertEq(rep.creditorWithdrawable(), interest);
    }

    function test_must_cover_interest() public {
        uint256 interest = rep.interestDue();
        vm.deal(creditee, interest);
        vm.prank(creditee);
        vm.expectRevert(bytes("Rep: must cover interest"));
        rep.makePayment{value: interest - 1}();
    }

    /// L-04 / M-05: penalty accrual returns explicitly and is time-gated.
    function test_missed_payment_accrues_penalty() public {
        uint256 interest = rep.interestDue();
        vm.warp(block.timestamp + 8 days); // past the due date
        bool cleared = rep.accrueMissedPayment();
        assertFalse(cleared);
        assertEq(rep.balance(), PRINCIPAL + interest); // penalty added
        assertEq(rep.missedPayments(), 1);
    }

    function test_creditor_withdraws() public {
        uint256 interest = rep.interestDue();
        vm.deal(creditee, interest);
        vm.prank(creditee);
        rep.makePayment{value: interest}();

        vm.prank(creditor);
        rep.withdraw();
        assertEq(creditor.balance, interest);
    }
}
