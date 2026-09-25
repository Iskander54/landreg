# LandReg — Smart Contract Security Review

**Reviewer:** Alex-Kevin Loembe
**Scope:** `contracts/Registry.sol`, `contracts/RoleManagement.sol`, `contracts/Mortgage.sol`, `contracts/Repayment.sol`, `contracts/MultiOwnership.sol`
**Compiler:** Solidity `^0.5.0` (OpenZeppelin Contracts 2.4)
**Type:** Self-review of an earlier learning project, redone with a current smart-contract-security methodology.

> This is a study project, not audited production code. I re-reviewed my own 2019-era contracts the way I would review any smart contract today, to document real vulnerability classes and their remediations. Findings are mapped to the [Smart Contract Weakness Classification (SWC) Registry](https://swcregistry.io/) where applicable.

## Methodology

Manual line-by-line review focused on: access control, value flows (ETH accounting), reentrancy, integer safety, external-call trust boundaries, and logic/spec conformance. In a production workflow I would pair this with automated tooling (Slither, Mythril) and Foundry property/fuzz + invariant tests; a Foundry proof-of-concept for the highest-severity finding is included under `test/foundry/`.

## Summary of findings

| ID | Severity | Contract | Finding |
|----|----------|----------|---------|
| H-01 | High | Registry | `newProperty` has no access control — anyone can register property records |
| H-02 | High | Mortgage | `withdraw` sends the entire contract balance, not the transaction amount |
| H-03 | High | MultiOwnership | `buyShare` takes the buyer's ETH but never pays the seller |
| M-01 | Medium | Mortgage | `executeTransaction` is externally callable and grants `Admin` on the Registry |
| M-02 | Medium | RoleManagement | `uint8` loop counter over an unbounded, growable array (DoS) |
| M-03 | Medium | Repayment / MultiOwnership | Ineffective guard checks: tautologies plus a wrong-element existence check |
| M-04 | Medium | Mortgage | Unchecked arithmetic (`_amount * ETHER`) under Solidity 0.5 (overflow) |
| M-05 | Medium | Repayment | Block-timestamp dependence for due dates and penalties |
| L-01 | Low | Registry | Constructor hardcodes a property and owner address (test artifact) |
| L-02 | Low | Registry | `deleteProperty` leaves a stale `listPointer`; `isProperty` can misresolve |
| L-03 | Low | RoleManagement | Event emitted inside the `onlyAdmin` modifier (gas/noise) |
| L-04 | Low | Multiple | Non-`view` functions declared with a return type but missing return paths |
| L-05 | Low | Registry | Redundant double inheritance of `Ownable` |
| I-01 | Info | All | EOL compiler (`0.5.x`); migrate to `0.8.x` (built-in overflow checks) + current OZ |
| I-02 | Info | Mortgage / MultiOwnership | Ad-hoc reentrancy flags instead of a guard + consistent pull-payments |

---

## High severity

### H-01 — `Registry.newProperty` is missing access control
**Location:** `contracts/Registry.sol:66` · **SWC-105 (Unprotected function) / SWC-106**

`updateProperty` and `deleteProperty` are both guarded by `onlyAdmin()`, but `newProperty` is `public` with no modifier:

```solidity
function newProperty(address payable ownerAddress, uint pin) public returns(bool success) {
    require(properties[pin].owner==address(0),"This PIN already exist");
    properties[pin].owner = ownerAddress;
    ...
}
```

**Impact:** Any account can create a land-registry entry for any PIN and assign it to any address. In a registry whose entire purpose is an authoritative record of ownership, an unauthenticated write is a critical integrity failure — an attacker can front-run legitimate registrations or seed arbitrary ownership.

**Recommendation:** Add the `onlyAdmin()` modifier (consistent with the sibling mutators). A Foundry PoC demonstrating the unauthorized write is in `test/foundry/AccessControl.t.sol`.

### H-02 — `Mortgage.withdraw` transfers the entire contract balance
**Location:** `contracts/Mortgage.sol:84-90`

```solidity
function withdraw(uint transactionId) internal{
    require(isParty[transactionId][msg.sender],"Only party");
    require(pendingWithdrawals[mortgages[transactionId].pin_owner]!=0);
    pendingWithdrawals[mortgages[transactionId].pin_owner]=0;
    mortgages[transactionId].pin_owner.transfer(address(this).balance);   // <-- whole balance
}
```

**Impact:** The contract is designed to hold many mortgages (`MortgageCount`, `mortgages[]`). `withdraw` pays out `address(this).balance` — the entire contract balance — rather than that transaction's `amount`. Executing one mortgage drains ETH escrowed for every other in-flight mortgage. This is a fund-accounting bug leading to loss of other users' funds.

**Recommendation:** Track and transfer only the per-transaction amount (`pendingWithdrawals[owner]` was set to `_amount*ETHER`; transfer that value, then zero it — pull-payment pattern), never `address(this).balance`.

### H-03 — `MultiOwnership.buyShare` never pays the seller
**Location:** `contracts/MultiOwnership.sol:212-219`

```solidity
function buyShare(uint256 index) public payable {
    require(msg.value==sales[index].amount,"Value doesn't match price.");
    require(index<=SafeMath.sub(sales.length,1),"Sale doesn't exist");
    transferOwnership(msg.sender,sales[index].owner,sales[index].pct);
    sales[index]=sales[SafeMath.sub(sales.length,1)];
    delete sales[SafeMath.sub(sales.length,1)];
    emit SharedSold(sales[index].owner, msg.sender, sales[index].pct);
}
```

**Impact:** The buyer sends `msg.value == price`, and ownership is transferred, but the ETH is **never forwarded to the seller** (`sales[index].owner`) — it stays trapped in the contract. The seller loses their share and receives nothing. Separately, the swap-and-pop overwrites `sales[index]` *before* the `emit`, so the event logs the wrong actors, and the `index == last` case deletes the just-written entry.

**Recommendation:** Forward the payment to the seller (pull-payment: credit `pendingWithdrawals[seller] += msg.value` and expose a `withdraw`). Cache `sales[index]` in memory before mutating the array, and emit from the cached copy.

---

## Medium severity

### M-01 — `Mortgage.executeTransaction` is externally callable and escalates Registry privileges
**Location:** `contracts/Mortgage.sol:172-185`

`executeTransaction` is `public payable` (not `internal`). Beyond being triggerable by anyone for any confirmed transaction, on success it calls into the Registry and **grants `Admin`** to a freshly created `Repayment` contract:

```solidity
Registry r = Registry(addr);
r.updateProperty(mortgages[transactionId].beneficiary, mortgages[transactionId].pin);
address repay = createRepayment(transactionId, addr);
r.grantPermission(repay, 'Admin');
```

**Impact:** (1) Restrict `executeTransaction` to `internal`/authorized callers. (2) Granting full `Admin` on the Registry to an auto-deployed contract is over-broad — a scoped role (e.g., `Repayment` allowed to update only its own `pin`) enforces least privilege. The `addr` parameter is caller-supplied, so the Registry target is not validated.

### M-02 — `uint8` loop counter over an unbounded array (DoS)
**Location:** `contracts/RoleManagement.sol:27-35`

```solidity
uint8 i=0;
while(i<UserRoles.length){ ... i++; }
```

`UserRoles` grows via `addRolesList`. Past 255 entries, `i++` wraps (Solidity 0.5 has no built-in overflow check) and the loop never terminates, permanently bricking every function that calls `checkExistingRole` (including `grantPermission`). **Recommendation:** use `uint256`, and prefer a `mapping(bytes32 => bool)` for O(1) existence checks instead of a linear string scan.

### M-03 — Ineffective guard checks (tautologies and a wrong-element existence check)
**Locations:** `Repayment.sol:93` (`if(change>=0)`, `change` is `uint256`); `MultiOwnership.sol:266` (`require(allOperations[allOperationsIndicies[operation]] >= 0)` on a `bytes32`); `:282` (`require(allOperations[allOperationsIndicies[operation]] != 0)`). · **SWC-129**

Two distinct problems:

- **Tautologies (always pass).** `change >= 0` on a `uint256`, and `>= 0` on a `bytes32`, can never be false, so the intended validation is a no-op.
- **Wrong-element existence check (`downVote`, `!= 0`).** When an operation does not exist, `allOperationsIndicies[operation]` is `0`, so the check reads `allOperations[0]` — an unrelated element — rather than detecting absence. Unlike the tautologies it *can* pass or fail, but for the wrong reason, so it does not actually verify that the operation exists.

**Recommendation:** track existence explicitly (e.g., `mapping(bytes32 => bool) exists`) and compare against explicit sentinels instead of relying on `>= 0` or on array contents at a possibly-default index.

### M-04 — Unchecked arithmetic under Solidity 0.5
**Location:** `contracts/Mortgage.sol` (`_amount*ETHER`, `_amount*ETHER` in `require`/`transfer`) · **SWC-101**

`Mortgage` performs multiplication without `SafeMath` (unlike `Repayment`/`MultiOwnership`). A large `_amount` can overflow, and the overflowed value is used both in the `msg.value` equality check and in `pendingWithdrawals`, enabling accounting inconsistencies. **Recommendation:** use `SafeMath` everywhere on 0.5, or migrate to 0.8 with checked arithmetic.

### M-05 — Block-timestamp dependence
**Location:** `contracts/Repayment.sol:24,89,110` (`now`, `dueDate`, penalty logic) · **SWC-116**

Payment windows and penalties key off `block.timestamp`, which miners can nudge (~15s). For 7-day periods the risk is limited, but it should be documented and, where value-relevant, tolerance-bounded. **Recommendation:** accept the timestamp with an explicit tolerance and avoid using it for fine-grained or adversarial timing.

---

## Low severity / best practice

- **L-01** `Registry` constructor hardcodes property `1` to `0xDf70…` — a test fixture that should not ship.
- **L-02** `deleteProperty` (`Registry.sol:88`) never resets the deleted PIN's `listPointer`; combined with `isProperty` indexing `propertyList[listPointer]`, a deleted PIN can misresolve. Reset the pointer / use an existence flag.
- **L-03** `RoleManagement.onlyAdmin` emits `SenderOnAdmin` inside the modifier (`:67`) on every admin call — unnecessary gas and log noise.
- **L-04** Non-`view` functions declared with a return type but lacking a return on all paths: `Mortgage.isConfirmed`, `MultiOwnership.checkUpVote`, `Repayment.MissedPayment` (else branch). Make control flow explicit.
- **L-05** `Registry is Ownable, RoleManagement` while `RoleManagement` is already `Ownable` — redundant; inherit once.
- **L-06** Roles are `string`-keyed (gas + no enumeration guarantees); prefer `bytes32`/enum + OZ `AccessControl`.

## Informational

- **I-01** Pragma `^0.5.0` is end-of-life. Migrate to `0.8.x` (built-in overflow/underflow checks remove a whole finding class) and current OpenZeppelin (`AccessControl`, `ReentrancyGuard`, `Ownable2Step`).
- **I-02** Value flows mix push-payments with ad-hoc reentrancy flags (`pendingBuying`, `pendingWithdrawals`). Standardize on Checks-Effects-Interactions, OZ `ReentrancyGuard`, and pull-over-push withdrawals.
- **I-03** Dead code and magic numbers: unused `notAchieved` modifier, commented-out fields, hardcoded `required = 3`.

## Remediation priority

1. **H-01, H-02, H-03** — correctness of ownership writes and ETH accounting; fix before any deployment handling value.
2. **M-01, M-04** — privilege scope and integer safety.
3. Migrate to Solidity 0.8 + current OpenZeppelin (**I-01/I-02**), which structurally removes M-04 and hardens the value flows.

## Remediation (implemented in contracts-v2)

Every finding above is fixed in a modern rewrite under `contracts-v2/` (Solidity 0.8, OpenZeppelin 5),
with Foundry tests under `test-v2/` that prove each fix. The original `contracts/` are left untouched
as the "before". The remediated contracts are the default Foundry profile, so run the suite with:

```bash
forge test
```

Result: **17 passing tests** across the contracts.

| Finding | Fixed by | Proven by |
|---|---|---|
| H-01 | REGISTRAR_ROLE gates every Registry mutator (OZ AccessControl) | `test_H01_newProperty_reverts_for_nonAdmin` |
| H-02 | `Mortgage.withdraw` pays each account's tracked credit, never the balance (pull-payment + `nonReentrant`) | `test_H02_withdraw_pays_only_tx_amount` |
| H-03 | `MultiOwnership.buyShare` credits the seller; sale cached before swap-and-pop | `test_H03_buyShare_pays_seller` |
| M-01 | Execution is `internal`; Mortgage holds a scoped REGISTRAR_ROLE, not admin | Mortgage flow tests |
| M-02 | AccessControl (bytes32 roles) replaces the uint8-looped string roles | Registry role tests |
| M-03 | Explicit operation-existence mapping; conditional surplus refund | `test_M03_*` (MultiOwnership + Repayment) |
| M-04 | Solidity 0.8 checked arithmetic | structural |
| M-05 | `block.timestamp` over day-granularity periods, documented | `test_missed_payment_accrues_penalty` |
| L-01 / L-02 | No hardcoded constructor state; existence flags + `pop()` | `test_delete_keeps_list_consistent` |
| L-03 / L-04 / L-05 / L-06 | No event-in-modifier; explicit returns; single inheritance; bytes32 roles | structural |

Note: the v2 contracts are a clean remediation, not a line-by-line port. A few tangled original flows
(e.g. `Mortgage` spawning a `Repayment` that received blanket Registry admin) were simplified as part
of the fix, and documented in each contract's header.
