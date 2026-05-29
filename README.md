# claudesaver

A Claude Code plugin that automatically saves a `resume-session.sh` script to your working directory every time a Claude session starts. Run `/claudesaver` to manage activation and settings per folder.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/djfrez/claudesaver/main/install.sh | bash
```

That's it. The plugin activates on the next Claude session — no restart needed.

## What it does

Every time you start a Claude session in a folder, claudesaver writes a `resume-session.sh` script there:

```bash
#!/bin/bash
# claudesaver: resume script — DO NOT COMMIT (contains session ID)
# Session dir: /your/project
claude --resume abc123-def456-...
```

To resume that session later, just run:

```bash
./resume-session.sh
```

## Security

- `resume-session.sh` is automatically added to `.gitignore` (if you're in a git repo) — the file contains your session ID and should not be committed
- The script is created with `chmod 700` (owner-execute only)
- Config is stored at `~/.claude/claudesaver/config.json` with `chmod 600` (owner read/write only)
- The plugin repo contains zero secrets — all user data stays in `~/.claude/claudesaver/`

## Managing settings

Run `/claudesaver` in any Claude session to open the settings panel:

```
claudesaver status for: /your/project

  Enabled:            YES  (global default)
  Skip permissions:   NO
  resume-session.sh:  EXISTS  →  ./resume-session.sh
```

Options available:
- **Activate / Deactivate** for the current folder
- **Enable / Disable `--dangerously-skip-permissions`** for the current folder (with explicit warning)
- **Edit global defaults** (applies to all folders without a specific override)
- **Reset folder to global defaults**

## Config

Settings are stored in `~/.claude/claudesaver/config.json`:

```json
{
  "enabled": true,
  "dangerouslySkipPermissions": false,
  "directories": {
    "/path/to/special-project": {
      "dangerouslySkipPermissions": true
    }
  }
}
```

Global defaults apply everywhere. Directory entries override the global default for that specific path.

## Default behavior

- **Enabled globally** — runs in every folder automatically
- **`--dangerously-skip-permissions` OFF** by default — enable explicitly per folder or globally

## Requirements

- Claude Code CLI
- Python 3 (pre-installed on macOS and most Linux systems)

## Uninstall

```bash
claude plugin uninstall claudesaver
```

This removes the plugin and its hooks. Your `~/.claude/claudesaver/config.json` is preserved (delete manually if needed).
