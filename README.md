# LandReg — Solidity smart contracts (Foundry, OpenZeppelin 5)

![CI](https://github.com/Iskander54/landreg/actions/workflows/ci.yml/badge.svg)

Ethereum land-registry smart contracts: a property registry with role-based access control, bank
mortgages held in escrow with multi-party confirmation, amortized loan repayment, and fractional
co-ownership with on-chain voting. Written in Solidity 0.8 and tested with Foundry.

The repository also tells a security story. `contracts-v2/` is the current, remediated code;
`contracts/` is an earlier 2019 version kept as the documented "before". A full
[security review](./SECURITY-REVIEW.md) catalogs 15 findings across the old contracts, and every fix
is proven by a Foundry test.

## Stack

- Solidity 0.8.28
- OpenZeppelin Contracts 5.7
- Foundry (forge, anvil, cast) with forge-std
- CI: GitHub Actions (formatting check + tests on every push)

## Quick start

```bash
git clone --recurse-submodules https://github.com/Iskander54/landreg.git
cd landreg
forge test          # 17 tests over the current contracts
forge fmt --check   # formatting
```

If you already cloned without submodules, run `forge install` first.

## Contracts (`contracts-v2/`)

| Contract | Responsibility |
|---|---|
| `Registry.sol` | Property PIN to owner records; every mutator gated by `REGISTRAR_ROLE` (OZ AccessControl). |
| `Mortgage.sol` | Bank loan escrow with multi-party confirmation; pull-payment withdrawals, ReentrancyGuard. |
| `Repayment.sol` | Amortized repayment: interest first, penalties, missed-payment handling. |
| `MultiOwnership.sol` | Fractional co-ownership: share trading (the seller is paid) and share-weighted voting. |

## Security review and remediation

The [security review](./SECURITY-REVIEW.md) documents 15 findings (3 High, 5 Medium, 5 Low, 2 Info)
in the original `contracts/`, each mapped to the [SWC registry](https://swcregistry.io/), plus a
finding-to-fix-to-test table for the remediation. The originals are left vulnerable on purpose, as a
worked find-and-fix example.

Reproduce the flagship finding (H-01, missing access control) live on the old code:

```bash
bash poc/h01-access-control.sh   # deploys the 0.5 Registry on anvil and exploits it
```

Build the original ("before") contracts:

```bash
FOUNDRY_PROFILE=legacy forge build
```

## Deploy (current Registry)

```bash
# local
anvil
forge create contracts-v2/Registry.sol:Registry --constructor-args <ADMIN_ADDRESS> \
  --rpc-url http://localhost:8545 --private-key <KEY> --broadcast

# Base Sepolia (encrypted keystore; never paste a raw key)
cast wallet import deployer --interactive
forge create contracts-v2/Registry.sol:Registry --constructor-args <ADMIN_ADDRESS> \
  --rpc-url https://sepolia.base.org --account deployer --broadcast
```

## Author

Alex-Kevin Loembe · linkedin.com/in/alex-kevin-loembe-2105
