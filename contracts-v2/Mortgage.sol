// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IRegistry {
    function updateProperty(address newOwner, uint256 pin) external;
}

/// @title Mortgage (remediated)
/// @notice Escrows a bank loan until all parties confirm, then pays the property owner and
///         transfers the property to the beneficiary.
/// @dev Fixes vs `contracts/Mortgage.sol`:
///      - H-02: `withdraw` pays each account's tracked credit, never `address(this).balance`,
///        so concurrent mortgages can no longer drain one another. Pull-payment + ReentrancyGuard.
///      - M-01: execution is `internal` (auto-triggered by the final confirmation), and the
///        contract needs only a scoped REGISTRAR_ROLE on the Registry, not blanket admin.
///      - M-04: Solidity 0.8 checked arithmetic replaces manual/absent SafeMath.
contract Mortgage is ReentrancyGuard {
    IRegistry public immutable registry;
    uint256 internal constant REQUIRED = 3; // bank, beneficiary, pinOwner

    struct Loan {
        address bank;
        address beneficiary;
        address pinOwner;
        uint256 pin;
        uint256 amount; // escrowed wei
        uint256 confirmations;
        bool executed;
    }

    uint256 public loanCount;
    mapping(uint256 => Loan) public loans;
    mapping(uint256 => mapping(address => bool)) public isParty;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(address => uint256) public pendingWithdrawals;

    event LoanSubmitted(uint256 indexed id, uint256 amount);
    event Confirmed(uint256 indexed id, address indexed party);
    event Executed(uint256 indexed id, address indexed paidOwner, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address registry_) {
        require(registry_ != address(0), "Mortgage: zero registry");
        registry = IRegistry(registry_);
    }

    /// @notice Fund and open a loan. The sender must deposit exactly `amount`.
    function submitTransaction(
        address bank,
        address beneficiary,
        address pinOwner,
        uint256 pin,
        uint256 amount
    ) external payable returns (uint256 id) {
        require(amount > 0, "Mortgage: zero amount");
        require(msg.value == amount, "Mortgage: deposit must equal amount");
        require(
            bank != address(0) && beneficiary != address(0) && pinOwner != address(0),
            "Mortgage: zero party"
        );
        require(
            bank != beneficiary && bank != pinOwner && beneficiary != pinOwner,
            "Mortgage: parties must differ"
        );

        id = loanCount++;
        Loan storage loan = loans[id];
        loan.bank = bank;
        loan.beneficiary = beneficiary;
        loan.pinOwner = pinOwner;
        loan.pin = pin;
        loan.amount = amount;

        isParty[id][bank] = true;
        isParty[id][beneficiary] = true;
        isParty[id][pinOwner] = true;
        emit LoanSubmitted(id, amount);

        _confirm(id, msg.sender); // the funder (bank) confirms on submit
    }

    function confirmTransaction(uint256 id) external {
        _confirm(id, msg.sender);
    }

    function _confirm(uint256 id, address party) internal {
        Loan storage loan = loans[id];
        require(loan.amount != 0, "Mortgage: no such loan");
        require(!loan.executed, "Mortgage: executed");
        require(isParty[id][party], "Mortgage: not a party");
        require(!confirmed[id][party], "Mortgage: already confirmed");

        confirmed[id][party] = true;
        loan.confirmations += 1;
        emit Confirmed(id, party);

        if (loan.confirmations == REQUIRED) {
            _execute(id);
        }
    }

    /// @dev M-01: internal; only reachable through the final confirmation.
    function _execute(uint256 id) internal {
        Loan storage loan = loans[id];
        loan.executed = true;
        // H-02: credit ONLY this loan's amount (pull-payment), never the contract balance.
        pendingWithdrawals[loan.pinOwner] += loan.amount;
        registry.updateProperty(loan.beneficiary, loan.pin);
        emit Executed(id, loan.pinOwner, loan.amount);
    }

    /// @notice Withdraw funds credited to the caller. Checks-Effects-Interactions + nonReentrant.
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Mortgage: nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Mortgage: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}
