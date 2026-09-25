// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Repayment (remediated)
/// @notice Amortized loan repayment: interest is charged per period on the outstanding balance,
///         payments cover interest first then principal, and missed periods accrue penalties.
/// @dev Fixes vs `contracts/Repayment.sol`:
///      - M-03: an overpayment is refunded only on a genuine surplus (`change > 0`), replacing the
///        always-true `if (change >= 0)`.
///      - L-04: every branch returns explicitly.
///      - M-05: due dates use `block.timestamp` over multi-day periods; documented as an accepted,
///        coarse-grained dependence (miner drift of seconds is immaterial at day granularity).
///      - 0.8 checked arithmetic (no manual SafeMath); pull-payment for the creditor.
contract Repayment is ReentrancyGuard {
    address public immutable creditor; // lender
    address public immutable creditee; // borrower
    uint256 public immutable ratePctPerPeriod; // e.g. 10 == 10% of balance per period
    uint256 public constant PERIOD = 7 days;

    uint256 public balance; // outstanding principal (wei)
    uint256 public dueDate;
    uint256 public missedPayments;
    uint256 public creditorWithdrawable;

    event Paid(
        address indexed from, uint256 interest, uint256 principal, uint256 newBalance, uint256 newDueDate
    );
    event Refunded(address indexed to, uint256 amount);
    event MissedPaymentAccrued(uint256 penalty, uint256 newBalance, uint256 newDueDate);
    event LoanCleared();
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address creditor_, address creditee_, uint256 principal, uint256 ratePctPerPeriod_) {
        require(creditor_ != address(0) && creditee_ != address(0), "Rep: zero party");
        require(principal > 0, "Rep: zero principal");
        creditor = creditor_;
        creditee = creditee_;
        balance = principal;
        ratePctPerPeriod = ratePctPerPeriod_;
        dueDate = block.timestamp + PERIOD;
    }

    function interestDue() public view returns (uint256) {
        return (balance * ratePctPerPeriod) / 100;
    }

    /// @notice Make a payment. Interest is taken first; the remainder reduces principal; any
    ///         surplus beyond the full balance is refunded.
    function makePayment() external payable nonReentrant {
        require(balance > 0, "Rep: loan cleared");
        uint256 interest = interestDue();
        require(msg.value >= interest, "Rep: must cover interest");

        uint256 principalPart = msg.value - interest;
        uint256 change = 0;
        if (principalPart > balance) {
            // M-03: refund only a real surplus (previously `if (change >= 0)`, always true).
            change = principalPart - balance;
            principalPart = balance;
        }

        balance -= principalPart;
        creditorWithdrawable += (msg.value - change);
        dueDate = block.timestamp + PERIOD;

        if (change > 0) {
            (bool ok,) = payable(msg.sender).call{ value: change }("");
            require(ok, "Rep: refund failed");
            emit Refunded(msg.sender, change);
        }

        emit Paid(msg.sender, interest, principalPart, balance, dueDate);
        if (balance == 0) {
            emit LoanCleared();
        }
    }

    /// @notice Accrue a penalty once a period lapses; after 4 misses the loan is cleared.
    /// @return cleared true if too many missed payments cancelled the loan.
    function accrueMissedPayment() external returns (bool cleared) {
        require(block.timestamp > dueDate, "Rep: not overdue");
        if (missedPayments < 4) {
            missedPayments += 1;
            uint256 penalty = interestDue();
            balance += penalty;
            dueDate = block.timestamp + PERIOD;
            emit MissedPaymentAccrued(penalty, balance, dueDate);
            return false; // L-04: explicit return on every path
        } else {
            balance = 0;
            emit LoanCleared();
            return true;
        }
    }

    function withdraw() external nonReentrant {
        require(msg.sender == creditor, "Rep: only creditor");
        uint256 amount = creditorWithdrawable;
        require(amount > 0, "Rep: nothing to withdraw");
        creditorWithdrawable = 0;
        (bool ok,) = payable(creditor).call{ value: amount }("");
        require(ok, "Rep: transfer failed");
        emit Withdrawn(creditor, amount);
    }
}
