# Slither static-analysis report

Two runs of [Slither](https://github.com/crytic/slither) (Trail of Bits' static analyzer): the
original 2019 contracts and the remediated `contracts-v2/`. Raw output is in `slither-legacy.txt`
and `slither-v2.txt`. Slither also runs in CI on the current contracts (see `.github/workflows/ci.yml`).

## Original contracts (`contracts/`, Solidity 0.5): 120 findings

Slither independently flagged the mechanical vulnerabilities from the manual review, including
high-severity ones:

- **reentrancy-eth** in `Repayment.makePayment` and `Mortgage.executeTransaction` (external calls interleaved with state changes).
- **arbitrary-send-eth** in `MultiOwnership.buyProperty` (sends ETH to an arbitrary destination).
- **incorrect-equality** (dangerous strict comparisons, the tautology family, finding M-03).
- **controlled-array-length** on the `RoleManagement` role array (finding M-02).
- **unchecked return values** (`Registry.updateProperty` return ignored by callers).
- **reentrancy-events / reentrancy-benign** across the value-handling contracts.

What Slither did **not** flag: **H-01** (missing access control on `newProperty`) and **H-03** (the
seller is never paid in `buyShare`). Those are semantic / authorization bugs a static analyzer cannot
infer from control flow. That is the point: static analysis and manual review are complementary.
Slither confirmed the mechanical issues; the manual review caught the logic and access-control bugs
Slither missed.

## Remediated contracts (`contracts-v2/`, Solidity 0.8): 7 findings, all low / informational

No `reentrancy-eth`, no `arbitrary-send-eth`, no `incorrect-equality`. What remains:

- **low-level-calls** — the `.call{value:}` used for pull-payment withdrawals (the recommended pattern).
- **reentrancy-events** — an event emitted after an external call; benign here, since every such function uses `nonReentrant`.
- **timestamp** — `block.timestamp` in `Repayment` (finding M-05, accepted at day granularity and documented).
- **missing-inheritance** — a false positive: `Mortgage` declares a local `IRegistry` interface, so Slither suggests `Registry` "should inherit" it. Not applicable.

## Reproduce

```bash
FOUNDRY_PROFILE=legacy slither . --filter-paths "lib|test|node_modules"   # originals (Solidity 0.5)
slither . --filter-paths "test-v2|lib"                                    # remediated (Solidity 0.8)
```
