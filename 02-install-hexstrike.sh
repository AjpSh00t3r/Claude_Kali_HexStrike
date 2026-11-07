#!/usr/bin/env bash
#
# 02-install-hexstrike.sh
# Install HexStrike AI (https://github.com/0x4m4/hexstrike-ai) and build
# its Python virtualenv.
#
# IMPORTANT: the venv is built with Python 3.13, NOT the system default.
# Kali rolling currently ships Python 3.14, on which pip backtracks forever
# installing `angr` (its binary deps have no 3.14 wheels yet). Python 3.13
# installs everything cleanly from wheels.
#
# Part of: Claude Desktop + HexStrike AI on Kali
# Run order:  01-install-claude-desktop.sh -> 02 (this) -> 03-configure-mcp.sh
#
set -euo pipefail

echo "==> [2/3] Installing HexStrike AI + Python 3.13 venv"

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: Debian-based distro (apt) required." >&2; exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: run as your normal user, not root." >&2; exit 1
fi

HEX_DIR="$HOME/hexstrike-ai"
REPO="https://github.com/0x4m4/hexstrike-ai.git"
PYBIN="python3.13"

# --- prerequisites -------------------------------------------------------
echo "--> installing prerequisites (git, curl, build tools, $PYBIN + venv/dev)"
sudo apt-get update
sudo apt-get install -y git curl build-essential "$PYBIN" "${PYBIN}-venv" "${PYBIN}-dev"

if ! command -v "$PYBIN" >/dev/null 2>&1; then
  echo "ERROR: $PYBIN is not available from apt on this system." >&2
  echo "       HexStrike's dependencies need Python 3.13 wheels." >&2
  echo "       Install Python 3.13 another way and re-run, or edit PYBIN above." >&2
  exit 1
fi

# --- clone / update ------------------------------------------------------
if [ -d "$HEX_DIR/.git" ]; then
  echo "--> updating existing clone at $HEX_DIR"
  git -C "$HEX_DIR" pull --ff-only || echo "   (fast-forward pull skipped)"
else
  echo "--> cloning $REPO -> $HEX_DIR"
  git clone "$REPO" "$HEX_DIR"
fi

# --- virtualenv ----------------------------------------------------------
echo "--> (re)building venv with $PYBIN at $HEX_DIR/hexstrike-env"
rm -rf "$HEX_DIR/hexstrike-env"
"$PYBIN" -m venv "$HEX_DIR/hexstrike-env"

PIP="$HEX_DIR/hexstrike-env/bin/pip"
echo "--> upgrading pip"
"$PIP" install --upgrade pip
echo "--> installing requirements (large tree: angr, mitmproxy, pwntools... a few minutes)"
"$PIP" install --prefer-binary -r "$HEX_DIR/requirements.txt"

echo
echo "==> HexStrike installed at $HEX_DIR"
echo "    venv python: $HEX_DIR/hexstrike-env/bin/python3 ($("$HEX_DIR/hexstrike-env/bin/python3" --version))"
echo "    Note: pwntools + bitstring 5.x may warn 'ConstBitStream' on some imports."
echo "          This does NOT affect the HexStrike server or MCP bridge (verified)."
echo "          Only certain pwntools binary-exploit features need: pip install 'bitstring<4.3'"
echo "    Next: ./03-configure-mcp.sh"
