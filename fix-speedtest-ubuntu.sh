#!/usr/bin/env bash
set -euo pipefail

log(){ echo -e "\n[+] $*"; }
warn(){ echo -e "\n[!] $*" >&2; }
die(){ warn "$*"; exit 1; }

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run als root (sudo -i)."

log "Detecting Ubuntu version..."
source /etc/os-release || die "Cannot detect OS."
UBUNTU_CODENAME="${VERSION_CODENAME:-}"

if [[ -z "${UBUNTU_CODENAME:-}" ]]; then
  die "Could not detect Ubuntu codename."
fi

log "Detected Ubuntu codename: ${UBUNTU_CODENAME}"

log "Installing curl (if missing)..."
apt-get update -y
apt-get install -y curl ca-certificates gnupg

log "Adding Ookla repository..."
curl -fsSL https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh -o /tmp/ookla.sh
bash /tmp/ookla.sh

REPO_FILE="/etc/apt/sources.list.d/ookla_speedtest-cli.list"

if [[ ! -f "$REPO_FILE" ]]; then
  die "Repo file not found: $REPO_FILE"
fi

if [[ "$UBUNTU_CODENAME" == "noble" ]]; then
  log "Ubuntu 24.04 (noble) detected."
  log "Applying workaround: switching repo to jammy..."
  sed -i 's/noble/jammy/g' "$REPO_FILE"
fi

log "Updating package lists..."
apt update

log "Installing speedtest..."
apt-get install -y speedtest

log "Testing speedtest installation..."
if command -v speedtest >/dev/null 2>&1; then
  log "Speedtest installed successfully."
  speedtest --version
else
  die "Speedtest installation failed."
fi

log "Done."
