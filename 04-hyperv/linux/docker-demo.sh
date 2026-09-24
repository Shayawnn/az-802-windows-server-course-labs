#!/usr/bin/env bash
set -euo pipefail

echo "AZ-802 LAB | Docker container lifecycle"

if command -v docker >/dev/null 2>&1; then
  echo "[OK] Docker is already installed."
elif command -v apt-get >/dev/null 2>&1; then
  echo "Step 1 | Install Docker from the Ubuntu/Debian package repository"
  sudo apt-get update
  sudo apt-get install -y docker.io curl
  sudo systemctl enable --now docker
else
  echo "[SKIP] Automatic Docker installation is implemented for Ubuntu/Debian only. Install Docker for this distribution, then rerun the script."
  exit 0
fi

echo "Step 2 | Verify Docker and curl"
sudo docker --version
command -v curl >/dev/null 2>&1 || { echo "[FAIL] curl is required for the HTTP verification step."; exit 1; }

echo "Step 3 | Create or replace the disposable nginx container"
if sudo docker ps -a --format '{{.Names}}' | grep -qx 'az802-web-demo'; then
  sudo docker rm -f az802-web-demo >/dev/null
fi
sudo docker run --name az802-web-demo -d -p 8080:80 nginx:alpine >/dev/null
sudo docker ps --filter name=az802-web-demo

echo "Step 4 | Verify the HTTP endpoint"
curl --fail --silent --show-error http://localhost:8080/ >/dev/null
echo "[OK] nginx responded on http://localhost:8080/"

if [[ "${1:-}" == "--cleanup" ]]; then
  echo "Step 5 | Remove the disposable container"
  sudo docker rm -f az802-web-demo >/dev/null
  echo "[OK] Container removed."
else
  echo "[INFO] Run this script with --cleanup when you want to remove az802-web-demo."
fi
