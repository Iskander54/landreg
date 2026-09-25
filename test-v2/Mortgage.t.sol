// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../contracts-v2/Registry.sol";
import {Mortgage} from "../contracts-v2/Mortgage.sol";

/// @dev Proves the Mortgage remediations, above all H-02 (per-loan escrow accounting).
contract MortgageTest is Test {
    Registry reg;
    Mortgage mortgage;

    address bankA = makeAddr("bankA");
    address benA = makeAddr("benA");
    address ownerA = makeAddr("ownerA");
    address bankB = makeAddr("bankB");
    address benB = makeAddr("benB");
    address ownerB = makeAddr("ownerB");

    uint256 constant PIN_A = 100;
    uint256 constant PIN_B = 200;
    uint256 constant AMT_A = 1 ether;
    uint256 constant AMT_B = 3 ether;

    function setUp() public {
        reg = new Registry(address(this));
        mortgage = new Mortgage(address(reg));
        // M-01: scoped privilege — the Mortgage may update properties, but is not a registry admin.
        reg.grantRole(reg.REGISTRAR_ROLE(), address(mortgage));
        reg.newProperty(ownerA, PIN_A);
        reg.newProperty(ownerB, PIN_B);
    }

    function _runLoan(address bank, address ben, address owner, uint256 pin, uint256 amt)
        internal
        returns (uint256 id)
    {
        vm.deal(bank, amt);
        vm.prank(bank);
        id = mortgage.submitTransaction{value: amt}(bank, ben, owner, pin, amt); // bank confirms (1/3)
        vm.prank(ben);
        mortgage.confirmTransaction(id); // 2/3
        vm.prank(owner);
        mortgage.confirmTransaction(id); // 3/3 -> executes
    }

    /// H-02 FIXED: two loans escrowed together; withdrawing one pays only its amount.
    function test_H02_withdraw_pays_only_tx_amount() public {
        _runLoan(bankA, benA, ownerA, PIN_A, AMT_A);
        _runLoan(bankB, benB, ownerB, PIN_B, AMT_B);

        assertEq(mortgage.balance(), AMT_A + AMT_B);
        assertEq(mortgage.pendingWithdrawals(ownerA), AMT_A);
        assertEq(mortgage.pendingWithdrawals(ownerB), AMT_B);

        // ownerA withdraws -> exactly AMT_A; ownerB's escrow stays put.
        vm.prank(ownerA);
        mortgage.withdraw();
        assertEq(ownerA.balance, AMT_A);
        assertEq(mortgage.balance(), AMT_B); // the pre-fix bug would have drained this to 0
        assertEq(mortgage.pendingWithdrawals(ownerA), 0);

        vm.prank(ownerB);
        mortgage.withdraw();
        assertEq(ownerB.balance, AMT_B);
        assertEq(mortgage.balance(), 0);

        // properties transferred to the beneficiaries
        assertEq(reg.getPropertyOwner(PIN_A), benA);
        assertEq(reg.getPropertyOwner(PIN_B), benB);
    }

    function test_nonParty_cannot_confirm() public {
        vm.deal(bankA, AMT_A);
        vm.prank(bankA);
        uint256 id = mortgage.submitTransaction{value: AMT_A}(bankA, benA, ownerA, PIN_A, AMT_A);
        vm.prank(makeAddr("stranger"));
        vm.expectRevert(bytes("Mortgage: not a party"));
        mortgage.confirmTransaction(id);
    }

    function test_deposit_must_equal_amount() public {
        vm.deal(bankA, AMT_A);
        vm.prank(bankA);
        vm.expectRevert(bytes("Mortgage: deposit must equal amount"));
        mortgage.submitTransaction{value: 0.5 ether}(bankA, benA, ownerA, PIN_A, AMT_A);
    }
}
