#!/usr/bin/env bash
#
# 03-configure-mcp.sh
# Point Claude Desktop at the HexStrike MCP server, install the control
# script, and (unless NO_SERVICE=1) a systemd --user service that
# auto-starts the server at login and restarts it on crash.
#
#   NO_SERVICE=1 ./03-configure-mcp.sh   # skip the autostart service
#
# Part of: Claude Desktop + HexStrike AI on Kali
# Run order:  01-install-claude-desktop.sh -> 02-install-hexstrike.sh -> 03 (this)
#
set -euo pipefail

echo "==> [3/3] Configuring HexStrike MCP for Claude Desktop"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEX_DIR="$HOME/hexstrike-ai"
VENV_PY="$HEX_DIR/hexstrike-env/bin/python3"
MCP_BRIDGE="$HEX_DIR/hexstrike_mcp.py"
CFG_DIR="$HOME/.config/Claude"
CFG="$CFG_DIR/claude_desktop_config.json"
PORT=8888

if [ ! -x "$VENV_PY" ]; then
  echo "ERROR: $VENV_PY not found. Run ./02-install-hexstrike.sh first." >&2
  exit 1
fi
if [ ! -f "$MCP_BRIDGE" ]; then
  echo "ERROR: $MCP_BRIDGE not found. Is HexStrike installed?" >&2
  exit 1
fi

# --- quit Claude Desktop if running (it rewrites its config on exit) -----
if pgrep -f "[c]laude-desktop" >/dev/null 2>&1; then
  echo "--> Claude Desktop is running; stopping it so it won't overwrite the config"
  pkill -f "[c]laude-desktop" 2>/dev/null || true
  sleep 3
fi

# --- write the MCP config (clean, hexstrike-only) ------------------------
mkdir -p "$CFG_DIR"
if [ -f "$CFG" ]; then
  cp "$CFG" "$CFG.bak-$(date +%s)"
  echo "--> backed up existing config -> $CFG.bak-*"
fi
cat > "$CFG" <<EOF
{
  "mcpServers": {
    "hexstrike-ai": {
      "command": "$VENV_PY",
      "args": [
        "$MCP_BRIDGE",
        "--server",
        "http://localhost:$PORT"
      ],
      "timeout": 300,
      "disabled": false
    }
  }
}
EOF
echo "--> wrote $CFG"

# --- install the control script ------------------------------------------
if [ -f "$SCRIPT_DIR/hexstrike.sh" ]; then
  cp "$SCRIPT_DIR/hexstrike.sh" "$HEX_DIR/hexstrike.sh"
  chmod +x "$HEX_DIR/hexstrike.sh"
  echo "--> installed control script -> $HEX_DIR/hexstrike.sh"
fi

# --- systemd --user autostart service ------------------------------------
if [ "${NO_SERVICE:-0}" != "1" ]; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  UNIT_DIR="$HOME/.config/systemd/user"
  mkdir -p "$UNIT_DIR"
  cat > "$UNIT_DIR/hexstrike.service" <<EOF
[Unit]
Description=HexStrike AI MCP server (:$PORT)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$HEX_DIR
ExecStart=$VENV_PY $HEX_DIR/hexstrike_server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
  echo "--> installed systemd unit -> $UNIT_DIR/hexstrike.service"
  if systemctl --user daemon-reload 2>/dev/null && \
     systemctl --user enable --now hexstrike.service 2>/dev/null; then
    echo "--> service enabled; HexStrike auto-starts at login and restarts on crash"
  else
    echo "WARN: could not talk to the systemd --user instance from here." >&2
    echo "      Run inside your Kali graphical session:" >&2
    echo "        systemctl --user daemon-reload && systemctl --user enable --now hexstrike.service" >&2
  fi
else
  echo "--> NO_SERVICE=1: skipping autostart service."
  echo "    Start the server manually with: $HEX_DIR/hexstrike.sh start"
fi

echo
echo "==> Done!"
echo "    1) Make sure the server is up:  $HEX_DIR/hexstrike.sh status"
echo "    2) Launch Claude Desktop."
echo "    3) Confirm 'hexstrike-ai' shows as a connected MCP server with its tools."
