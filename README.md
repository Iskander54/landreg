# LandReg — a land-registry dApp on Ethereum (Solidity)

LandReg is a set of Ethereum smart contracts (plus a React / web3.js client) that model a municipal
land registry: authoritative property records, role-based permissions, bank mortgages held in escrow
with multi-party confirmation, amortized loan repayment, and fractional multi-ownership with on-chain
governance voting.

It began as a ConsenSys-era study project (Truffle + web3.js). I have since **re-reviewed it with a
current smart-contract-security methodology** and modernized the tooling with **Foundry**, including a
live, reproducible proof-of-concept for the highest-severity finding.

## Contracts

| Contract | Responsibility |
|----------|----------------|
| `Registry.sol` | Source-of-truth mapping of property PINs to owners (create / update / delete). |
| `RoleManagement.sol` | Role-based access control (Admin / Client / Owner / Bank) on top of OpenZeppelin `Roles`. |
| `Mortgage.sol` | Bank loan escrow: parties, per-transaction confirmations, execution, and repayment spawning. |
| `Repayment.sol` | Amortized repayment schedule with interest, penalties, and missed-payment handling. |
| `MultiOwnership.sol` | Fractional co-ownership of a property with share trading and percentage-weighted voting. |

Frontend: `client/` (React + `web3.js`).

## Security review

A full self-audit lives in **[SECURITY-REVIEW.md](./SECURITY-REVIEW.md)**: 15 findings across the five
contracts (3 High, 5 Medium, plus Low/Informational), each mapped to the SWC registry with impact and
remediation. Highlights:

- **H-01** `Registry.newProperty` has no access control, so any account can write ownership records.
- **H-02** `Mortgage.withdraw` transfers the entire contract balance rather than the transaction amount.
- **H-03** `MultiOwnership.buyShare` takes the buyer's ETH but never pays the seller.

### Reproduce the top finding (H-01) live

A runnable PoC spins up a local `anvil` chain, deploys the Registry, and shows an unprivileged account
registering a property while the guarded `updateProperty` correctly reverts:

```bash
npm install              # brings in OpenZeppelin Contracts 2.4
bash poc/h01-access-control.sh
```

Expected output confirms the unauthorized write persists, and that the access model works where it is
actually applied.

## Build and test with Foundry

The contracts target Solidity `0.5.x` / OpenZeppelin 2.4, so `foundry.toml` pins `solc = 0.5.17`.

```bash
npm install        # OpenZeppelin 2.4 (remapped in foundry.toml)
forge build        # compiles all contracts under solc 0.5.17
```

> Note: Foundry's Solidity unit-test harness injects `0.6+` syntax, so it cannot run test contracts
> under `0.5`. The security PoC is therefore delivered as the `anvil` + `cast` script above, which
> exercises the deployed bytecode directly. The original Truffle/mocha suite remains under `test/`.

## Remediated contracts (v2)

Every finding in the review is fixed in `contracts-v2/` (Solidity 0.8, OpenZeppelin 5), with Foundry
tests in `test-v2/` that prove each fix. The original `contracts/` stay in place as the documented
"before". Because the fixed contracts are on 0.8, they can be unit-tested:

```bash
forge install                 # fetches OZ 5 + forge-std into lib/ (or: git submodule update --init)
FOUNDRY_PROFILE=v2 forge test
```

Expected: **17 passing tests**, including the exploit-now-reverts cases for H-01, H-02, and H-03. See
the remediation table in [SECURITY-REVIEW.md](./SECURITY-REVIEW.md).

## Deploy to a testnet

Deploy with `forge create` (bring your own funded testnet key and RPC; never commit a private key):

```bash
# Base Sepolia (get test ETH from a faucet first)
export BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
forge create contracts/Registry.sol:Registry \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --private-key "$YOUR_TESTNET_PRIVATE_KEY" \
  --broadcast
```

## Status

This is a learning project, not audited production code. The vulnerabilities documented in the security
review are intentionally left in place (with fixes described) so the repository doubles as a worked
example of finding and remediating common smart-contract weaknesses.

## Author

Alex-Kevin Loembe — [linkedin.com/in/alex-kevin-loembe-2105](https://linkedin.com/in/alex-kevin-loembe-2105)
