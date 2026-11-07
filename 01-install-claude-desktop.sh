#!/usr/bin/env bash
#
# 01-install-claude-desktop.sh
# Install Claude Desktop (official Linux beta) on Kali / Debian / Ubuntu.
#
# Part of: Claude Desktop + HexStrike AI on Kali
# Run order:  01 (this) -> 02-install-hexstrike.sh -> 03-configure-mcp.sh
#
set -euo pipefail

echo "==> [1/3] Installing Claude Desktop (official apt repo)"

# --- sanity checks -------------------------------------------------------
if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: this installer targets Debian-based distros (apt). Aborting." >&2
  exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: run as your normal user (the script calls sudo itself), not as root." >&2
  exit 1
fi

# --- already installed? --------------------------------------------------
if command -v claude-desktop >/dev/null 2>&1; then
  echo "Claude Desktop already installed: $(command -v claude-desktop)"
  exit 0
fi

KEYRING=/usr/share/keyrings/claude-desktop-archive-keyring.asc
LIST=/etc/apt/sources.list.d/claude-desktop.list

echo "--> adding Anthropic signing key -> $KEYRING"
sudo curl -fsSLo "$KEYRING" https://downloads.claude.ai/claude-desktop/key.asc

echo "--> adding apt repository -> $LIST"
echo "deb [signed-by=$KEYRING] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
  | sudo tee "$LIST" >/dev/null

echo "--> apt update && install claude-desktop"
sudo apt-get update
sudo apt-get install -y claude-desktop

echo
echo "==> Claude Desktop installed: $(command -v claude-desktop)"
echo "    Officially supported on Ubuntu 22.04+/Debian 12+ (x64/arm64)."
echo "    Kali is not an official target but installs and runs fine."
echo "    Next: ./02-install-hexstrike.sh"
