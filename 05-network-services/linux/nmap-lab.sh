#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 LAB_TARGET_HOST_OR_IP"
  exit 2
fi

echo "AZ-802 LAB | Nmap service enumeration"
if command -v nmap >/dev/null 2>&1; then
  echo "[OK] nmap is already installed."
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y nmap
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y nmap
elif command -v yum >/dev/null 2>&1; then
  sudo yum install -y nmap
else
  echo "[SKIP] Supported package manager not found. Install nmap manually for this distribution."
  exit 0
fi

nmap --version | head -n 1
echo "Step 1 | Enumerate selected Windows Server ports on $TARGET"
nmap -sV -p 80,443,3389,445 "$TARGET"
echo "Step 2 | Read harmless HTTP metadata when port 80 is available"
nmap --script http-title,http-headers -p 80 "$TARGET"
