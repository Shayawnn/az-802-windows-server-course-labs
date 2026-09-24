#!/usr/bin/env bash
set -euo pipefail

echo "AZ-802 LAB | Linux network checks"
ip addr
ip route

GATEWAY="${1:-}"
TARGET="${2:-}"
if [[ -n "$GATEWAY" ]]; then
  echo "Step 1 | Test the supplied lab gateway"
  ping -c 4 "$GATEWAY"
else
  echo "[INFO] Supply a gateway as argument 1 to test it."
fi

echo "Step 2 | Test public reachability"
ping -c 4 8.8.8.8 || echo "[WARN] ICMP to 8.8.8.8 failed; outbound access may still work if ICMP is filtered."

if command -v getent >/dev/null 2>&1; then
  getent hosts microsoft.com || true
fi
if [[ -n "$TARGET" ]]; then
  echo "Step 3 | Test the supplied peer hostname/address"
  ping -c 2 "$TARGET" || true
fi
