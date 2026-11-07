#!/usr/bin/env bash
# hexstrike.sh - control the HexStrike AI server (for Claude Desktop MCP)
# usage: ./hexstrike.sh {start|stop|restart|status|logs}
#
# Installed to ~/hexstrike-ai/hexstrike.sh by 03-configure-mcp.sh.
# NOTE: if you enabled the systemd --user service, prefer:
#   systemctl --user {start|stop|restart|status} hexstrike
# (this script's `stop` sends SIGTERM, which the service would auto-restart).
set -uo pipefail

HEX_DIR="$HOME/hexstrike-ai"
VENV_PY="$HEX_DIR/hexstrike-env/bin/python"
SERVER="$HEX_DIR/hexstrike_server.py"
LOG="$HEX_DIR/server.log"
PORT=8888
HEALTH="http://localhost:$PORT/health"

is_up()   { curl -s -m 3 "$HEALTH" >/dev/null 2>&1; }
srv_pids(){ pgrep -f "hexstrike_server.py" 2>/dev/null; }

start() {
  if is_up; then
    echo "HexStrike already running and healthy on :$PORT"
    return 0
  fi
  if [ ! -x "$VENV_PY" ]; then
    echo "ERROR: venv python not found at $VENV_PY (run 02-install-hexstrike.sh)" >&2
    return 1
  fi
  echo "Starting HexStrike server on :$PORT ..."
  ( cd "$HEX_DIR" && setsid nohup "$VENV_PY" "$SERVER" >"$LOG" 2>&1 </dev/null & )
  # Cold start probes 150+ tools, so /health can take ~30-60s to first answer.
  for _ in $(seq 1 60); do
    if is_up; then
      echo "HexStrike up on :$PORT (pids: $(srv_pids | tr '\n' ' ')). Log: $LOG"
      return 0
    fi
    sleep 1
  done
  if [ -n "$(srv_pids)" ]; then
    echo "HexStrike process started (pids: $(srv_pids | tr '\n' ' ')) but /health still warming up."
    echo "Tool probe usually finishes shortly - watch: ./hexstrike.sh logs"
    return 0
  fi
  echo "ERROR: server failed to start - see $LOG" >&2
  return 1
}

stop() {
  local p; p="$(srv_pids)"
  if [ -z "$p" ]; then echo "HexStrike not running"; return 0; fi
  echo "Stopping HexStrike (pids: $(echo "$p" | tr '\n' ' '))..."
  kill $p 2>/dev/null
  sleep 3
  p="$(srv_pids)"
  if [ -n "$p" ]; then echo "Force-killing: $(echo "$p" | tr '\n' ' ')"; kill -9 $p 2>/dev/null; fi
  echo "Stopped."
}

status() {
  if is_up; then
    echo "RUNNING - healthy on :$PORT (pids: $(srv_pids | tr '\n' ' '))"
  elif [ -n "$(srv_pids)" ]; then
    echo "PROCESS PRESENT but /health not responding (pids: $(srv_pids | tr '\n' ' ')) - check $LOG"
  else
    echo "STOPPED"
  fi
}

case "${1:-start}" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; start ;;
  status)  status ;;
  logs)    tail -n 40 -f "$LOG" ;;
  *) echo "usage: $0 {start|stop|restart|status|logs}" >&2; exit 2 ;;
esac
