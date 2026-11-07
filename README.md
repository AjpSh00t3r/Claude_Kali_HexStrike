# Claude Desktop + HexStrike AI on Kali

Three small scripts that set up [HexStrike AI](https://github.com/0x4m4/hexstrike-ai)
as an MCP server inside **Claude Desktop** on Kali Linux (and other Debian/Ubuntu systems).

> **"Claude Code" vs "Claude Desktop":** these scripts install **Claude Desktop**, the
> desktop GUI app — that's the one that reads `~/.config/Claude/claude_desktop_config.json`
> and hosts MCP servers. It is *not* the `claude` command-line tool (Claude Code CLI),
> which uses a different config. If you want the CLI instead, script 1 would differ.

## What you get

- Claude Desktop (official Linux beta) installed from Anthropic's apt repo
- HexStrike AI cloned with a working Python **3.13** virtualenv
- Claude Desktop configured to launch the HexStrike MCP bridge and talk to the
  HexStrike server on `http://localhost:8888`
- A `hexstrike.sh` control script and an optional `systemd --user` service that
  auto-starts the server at login

## Requirements

- A Debian-based distro with `apt` (built/tested on **Kali rolling**)
- `sudo` rights, run as your normal user (not root)
- Internet access
- ~1.5 GB free disk (Claude Desktop + HexStrike deps)

## Usage

Clone the repo, then run the scripts **in order**:

```bash
git clone https://github.com/AjpSh00t3r/Claude_Kali_HexStrike.git
cd Claude_Kali_HexStrike
chmod +x *.sh
./01-install-claude-desktop.sh     # Claude Desktop via official apt repo
./02-install-hexstrike.sh          # HexStrike + Python 3.13 venv
./03-configure-mcp.sh              # MCP config + control script + autostart service
```

Then launch **Claude Desktop** and confirm **hexstrike-ai** appears as a connected
MCP server with its tools.

To skip the autostart service and start the server manually instead:

```bash
NO_SERVICE=1 ./03-configure-mcp.sh
~/hexstrike-ai/hexstrike.sh start
```

## Managing the server

With the systemd service (recommended):

```bash
systemctl --user status  hexstrike
systemctl --user restart hexstrike
systemctl --user stop    hexstrike
```

Or with the control script (also good for logs):

```bash
~/hexstrike-ai/hexstrike.sh status
~/hexstrike-ai/hexstrike.sh logs      # live tail of server.log
~/hexstrike-ai/hexstrike.sh restart
```

## Why Python 3.13?

Kali rolling currently ships **Python 3.14**. HexStrike's dependency set (notably
`angr` and its binary deps) has **no 3.14 wheels yet**, so `pip` backtracks
endlessly and never finishes. Script 2 installs and builds the venv with
**Python 3.13**, where everything installs cleanly from prebuilt wheels.

## Known quirks

- **First start is slow.** On a cold start HexStrike probes 150+ tools (`which ...`),
  so `/health` can take ~30-60 s to first respond, then it's fast. Not a hang.
- **pwntools + bitstring.** `pwntools` with `bitstring 5.x` can raise
  `AttributeError: module 'bitstring' has no attribute 'ConstBitStream'` on some
  imports. The HexStrike server and MCP bridge still start fine; only certain
  pwntools binary-exploit features are affected. If you need them:
  `~/hexstrike-ai/hexstrike-env/bin/pip install 'bitstring<4.3'`.
- **Config gets overwritten.** Claude Desktop rewrites its config on exit, so
  script 3 quits a running Claude Desktop before writing. Quit Claude Desktop
  before re-running script 3.

## Files

| File | Purpose |
|------|---------|
| `01-install-claude-desktop.sh` | Install Claude Desktop (apt repo) |
| `02-install-hexstrike.sh`      | Clone HexStrike, build Python 3.13 venv, install deps |
| `03-configure-mcp.sh`          | Write MCP config, install control script + autostart service |
| `hexstrike.sh`                 | Server control helper (copied to `~/hexstrike-ai/` by script 3) |

## Responsible use

HexStrike AI is an **offensive security** toolkit. Only use it against systems you
own or are explicitly authorized to test. You are responsible for complying with all
applicable laws and rules of engagement.

## Credits

- HexStrike AI - https://github.com/0x4m4/hexstrike-ai
- Claude Desktop - https://www.anthropic.com
