# claudesaver

A [Claude Code](https://claude.ai/code) plugin that automatically saves a `resume-session.sh` script to your working directory every time a session starts. Pick up any session exactly where you left off with a single command.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/djfrez/claudesaver/main/install.sh | bash
```

Takes effect on the next Claude session — no restart required.

## How it works

Every time you open Claude Code in a folder, claudesaver writes a `resume-session.sh` to that directory:

```bash
#!/bin/bash
# claudesaver: resume script — DO NOT COMMIT (contains session ID)
# Session dir: /your/project
claude --resume abc123-def456-...
```

To jump back into that session later:

```bash
./resume-session.sh
```

If you're in a git repo, `/resume-session.sh` is automatically appended to `.gitignore` so it's never accidentally committed.

## /claudesaver — settings

Run `/claudesaver` inside any Claude session to manage settings for the current folder:

```
claudesaver status for: /your/project

  Enabled:            YES  (global default)
  Skip permissions:   NO
  resume-session.sh:  EXISTS  →  ./resume-session.sh
```

Available actions:

| Action | Scope |
|---|---|
| Activate / Deactivate | Current folder |
| Enable / Disable `--dangerously-skip-permissions` | Current folder (with warning) |
| Edit global defaults | All folders |
| Reset folder to global defaults | Current folder |

Settings are stored in `~/.claude/claudesaver/config.json`:

```json
{
  "enabled": true,
  "dangerouslySkipPermissions": false,
  "directories": {
    "/path/to/trusted-project": {
      "dangerouslySkipPermissions": true
    }
  }
}
```

Global defaults apply everywhere. Directory entries override them per path.

## Security

- **Auto-gitignore** — `/resume-session.sh` is added to `.gitignore` on creation (git repos only)
- **Restricted permissions** — `resume-session.sh` is `chmod 700` (owner-execute only); config is `chmod 600`
- **No secrets in the repo** — all user data lives in `~/.claude/claudesaver/`, never in the plugin repo
- **`--dangerously-skip-permissions` is opt-in** — disabled by default; the skill requires explicit confirmation before enabling, especially globally
- **Non-blocking hook** — all errors are caught silently; the hook never interrupts a session startup

## Requirements

- [Claude Code CLI](https://claude.ai/code)
- Python 3 (standard on macOS and most Linux systems)

## Uninstall

```bash
claude plugin uninstall claudesaver@djfrez
```

Removes the plugin and its hooks. Your config at `~/.claude/claudesaver/config.json` is preserved — delete it manually if you want a clean removal.
