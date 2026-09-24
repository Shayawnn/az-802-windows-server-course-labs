#!/usr/bin/env bash
set -euo pipefail

SERVER="${1:-}"
EXPORT="${2:-AZ802-NFS01}"
MOUNTPOINT="${3:-/mnt/az802-nfs01}"
if [[ -z "$SERVER" ]]; then
  echo "Usage: $0 SERVER [EXPORT_NAME] [MOUNT_POINT]"
  exit 2
fi

echo "AZ-802 LAB | Linux NFS client"
if command -v mount.nfs >/dev/null 2>&1; then
  echo "[OK] NFS client tools are already installed."
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y nfs-common
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y nfs-utils
elif command -v yum >/dev/null 2>&1; then
  sudo yum install -y nfs-utils
else
  echo "[SKIP] Supported package manager not found. Install the NFS client package manually."
  exit 0
fi

REMOTE="$SERVER:/$EXPORT"
sudo mkdir -p "$MOUNTPOINT"
CURRENT="$(findmnt -n -o SOURCE --target "$MOUNTPOINT" 2>/dev/null || true)"
if [[ -n "$CURRENT" && "$CURRENT" != "$REMOTE" ]]; then
  echo "[FAIL] $MOUNTPOINT is already mounted from $CURRENT, not $REMOTE."
  exit 1
elif [[ "$CURRENT" == "$REMOTE" ]]; then
  echo "[OK] $REMOTE is already mounted on $MOUNTPOINT."
else
  sudo mount -t nfs "$REMOTE" "$MOUNTPOINT"
fi
findmnt "$MOUNTPOINT"
ls -la "$MOUNTPOINT"
echo "hello from AZ-802 Linux NFS client" | sudo tee "$MOUNTPOINT/az802-linux-test.txt" >/dev/null
echo "[OK] Wrote $MOUNTPOINT/az802-linux-test.txt"
