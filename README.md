# LandReg

![CI](https://github.com/Iskander54/landreg/actions/workflows/ci.yml/badge.svg)
![Solidity](https://img.shields.io/badge/Solidity-0.8.28-363636)
![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-5.7-4E5EE4)
![Foundry](https://img.shields.io/badge/built%20with-Foundry-000000)

On-chain land registry: a set of Ethereum smart contracts that record property ownership, manage
role-based permissions, and settle bank mortgages, loan repayments, and fractional co-ownership. Built
with Foundry, OpenZeppelin 5, and a full test suite.

The repository doubles as a **security case study**. The contracts began as a 2019 study project;
`contracts/` preserves that original version, `SECURITY-REVIEW.md` documents 15 vulnerabilities found
in it, and `contracts-v2/` is a modern rewrite that fixes every one, with Foundry tests and Slither
static analysis proving the difference.

## Stack

| | |
|---|---|
| Language | Solidity 0.8.28 |
| Libraries | OpenZeppelin Contracts 5.7 (`AccessControl`, `ReentrancyGuard`) |
| Tooling | Foundry (forge, anvil, cast), forge-std |
| Analysis | Slither |
| CI | GitHub Actions: format check, tests, and static analysis on every push |

## Quick start

```bash
git clone --recurse-submodules https://github.com/Iskander54/landreg.git
cd landreg
forge test          # 17 tests over the current contracts
forge fmt --check   # formatting
```

Already cloned without submodules? Run `forge install`.

## Contracts

The current contracts live in `contracts-v2/`:

| Contract | Responsibility |
|---|---|
| `Registry.sol` | Property records (PIN to owner). Every mutator is gated by `REGISTRAR_ROLE` via OpenZeppelin `AccessControl`. |
| `Mortgage.sol` | Bank loan escrow with multi-party confirmation. Pull-payment withdrawals, `ReentrancyGuard`, per-loan accounting. |
| `Repayment.sol` | Amortized repayment: interest first, then principal, with penalties for missed periods. |
| `MultiOwnership.sol` | Fractional co-ownership: share trading (the seller is paid) and share-weighted voting. |

## Testing

```bash
forge test -vv                     # unit tests for the current contracts (Solidity 0.8)
bash poc/h01-access-control.sh     # live exploit of the top finding against the original code
FOUNDRY_PROFILE=legacy forge build # build the original ("before") contracts (Solidity 0.5)
```

Every finding is mapped to a test in `SECURITY-REVIEW.md`, including exploit-now-reverts cases for the
three High-severity bugs.

## Security

`SECURITY-REVIEW.md` catalogs 15 findings (3 High, 5 Medium, 5 Low, 2 Informational) in the original
contracts, each mapped to the [SWC registry](https://swcregistry.io/), with a finding-to-fix-to-test
table for the remediation. Highlights:

- **H-01** missing access control on `Registry.newProperty` (anyone could register ownership).
- **H-02** `Mortgage.withdraw` sent the entire contract balance instead of the loan amount.
- **H-03** `MultiOwnership.buyShare` took the buyer's payment without paying the seller.

`SLITHER.md` reports the static-analysis pass: Slither independently flags high-severity `reentrancy-eth`
and `arbitrary-send-eth` on the originals, and finds no high-severity issues on the remediated contracts.

## Deploy

```bash
# local (anvil)
anvil
forge create contracts-v2/Registry.sol:Registry --constructor-args <ADMIN_ADDRESS> \
  --rpc-url http://localhost:8545 --private-key <KEY> --broadcast

# Base Sepolia (encrypted keystore; never paste a raw private key)
cast wallet import deployer --interactive
forge create contracts-v2/Registry.sol:Registry --constructor-args <ADMIN_ADDRESS> \
  --rpc-url https://sepolia.base.org --account deployer --broadcast
```

## Layout

```
contracts-v2/   current contracts (Solidity 0.8, the deployable code)
test-v2/        Foundry test suite
contracts/      original 2019 contracts, kept as the reviewed "before"
poc/            live exploit script for finding H-01
SECURITY-REVIEW.md  the 15 findings and their remediations
SLITHER.md          static-analysis report
```

## Author

Alex-Kevin Loembe · [linkedin.com/in/alex-kevin-loembe-2105](https://linkedin.com/in/alex-kevin-loembe-2105)

## License

See [LICENSE](./LICENSE).
