// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MultiOwnership (remediated)
/// @notice Fractional co-ownership of a property: owners hold percentage shares, can list a
///         share for sale, and vote on operations weighted by their share.
/// @dev Fixes vs `contracts/MultiOwnership.sol`:
///      - H-03: `buyShare` credits the SELLER with the payment (pull-payment) instead of leaving
///        it trapped in the contract; the sale is cached before the swap-and-pop and removed with
///        `pop()`, so the event and array stay consistent.
///      - M-03: operation existence is tracked in an explicit mapping, replacing the tautological
///        `>= 0` check and the wrong-element `!= 0` read.
contract MultiOwnership is ReentrancyGuard {
    struct Sale {
        address seller;
        uint256 pct; // percentage points offered (1..100)
        uint256 price; // wei
    }

    mapping(address => uint256) public ownershipPct;
    Sale[] public sales;
    mapping(address => uint256) public pendingWithdrawals;

    mapping(bytes32 => bool) public operationExists;
    mapping(bytes32 => uint256) public operationVotes;
    mapping(bytes32 => mapping(address => bool)) public voted;

    event SharePutForSale(uint256 indexed index, address indexed seller, uint256 pct, uint256 price);
    event ShareSold(
        uint256 indexed index, address indexed seller, address indexed buyer, uint256 pct, uint256 price
    );
    event Withdrawn(address indexed to, uint256 amount);
    event OperationProposed(bytes32 indexed op, address indexed proposer);
    event OperationVoted(bytes32 indexed op, address indexed voter, uint256 totalPct);

    constructor(address initialOwner) {
        require(initialOwner != address(0), "MO: zero owner");
        ownershipPct[initialOwner] = 100;
    }

    modifier onlyOwner() {
        require(ownershipPct[msg.sender] > 0, "MO: not an owner");
        _;
    }

    /// @notice List part of your ownership for sale.
    function sellShare(uint256 pct, uint256 price) external onlyOwner returns (uint256 index) {
        require(pct > 0 && pct <= ownershipPct[msg.sender], "MO: bad pct");
        sales.push(Sale({ seller: msg.sender, pct: pct, price: price }));
        index = sales.length - 1;
        emit SharePutForSale(index, msg.sender, pct, price);
    }

    /// @notice Buy a listed share. H-03: the seller is paid; funds are never trapped.
    function buyShare(uint256 index) external payable nonReentrant {
        require(index < sales.length, "MO: no such sale");
        Sale memory sale = sales[index]; // cache BEFORE mutating the array
        require(msg.value == sale.price, "MO: wrong price");
        require(sale.seller != msg.sender, "MO: buying own share");
        require(ownershipPct[sale.seller] >= sale.pct, "MO: seller lacks pct");

        ownershipPct[sale.seller] -= sale.pct;
        ownershipPct[msg.sender] += sale.pct;

        // H-03: credit the seller (pull-payment) instead of trapping the ETH.
        pendingWithdrawals[sale.seller] += msg.value;

        uint256 last = sales.length - 1;
        if (index != last) {
            sales[index] = sales[last];
        }
        sales.pop();

        emit ShareSold(index, sale.seller, msg.sender, sale.pct, sale.price);
    }

    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "MO: nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{ value: amount }("");
        require(ok, "MO: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    // ---- operation voting (M-03: explicit existence, no tautology) ----

    function proposeOperation(bytes32 op) external onlyOwner {
        require(!operationExists[op], "MO: op exists");
        operationExists[op] = true;
        emit OperationProposed(op, msg.sender);
    }

    function voteOperation(bytes32 op) external onlyOwner {
        require(operationExists[op], "MO: no such op"); // real existence check
        require(!voted[op][msg.sender], "MO: already voted");
        voted[op][msg.sender] = true;
        operationVotes[op] += ownershipPct[msg.sender];
        emit OperationVoted(op, msg.sender, operationVotes[op]);
    }

    function salesCount() external view returns (uint256) {
        return sales.length;
    }
}
