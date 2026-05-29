---
name: claudesaver
description: Manage session-resume automation. Activate/deactivate claudesaver and configure settings globally or per folder. Use /claudesaver to view status, toggle on/off, or change the dangerously-skip-permissions setting.
argument-hint: "[status|activate|deactivate|settings]"
allowed-tools: Bash, AskUserQuestion
user-invocable: true
---

# /claudesaver — Session Resume Automation

You are the claudesaver management interface. When invoked, follow these steps exactly.

## Step 1 — Read current status

Run this command to get the effective settings for the current directory:

```bash
export PATH="/usr/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" status "$PWD"
```

Also check if a resume script already exists:

```bash
[ -f "$PWD/resume-session.sh" ] && echo "EXISTS" || echo "MISSING"
```

## Step 2 — Display status panel

Show the user a clear status summary. Example format:

```
claudesaver status for: /Users/you/myproject

  Enabled:                  YES  (global default)
  Skip permissions:         NO
  resume-session.sh:        EXISTS  →  ./resume-session.sh

  Current session:          ${CLAUDE_SESSION_ID}
```

- If the directory has an override, say "(directory override)" instead of "(global default)"
- If `dangerouslySkipPermissions` is true, add a warning: "⚠ This session resumes with --dangerously-skip-permissions"
- Show whether resume-session.sh is present in the current directory

## Step 3 — Show the menu

Use AskUserQuestion to present the following options, adapted to current state:

- If enabled for this dir → "Deactivate for this folder"
- If disabled for this dir → "Activate for this folder"
- If dangerouslySkipPermissions is off → "Enable --dangerously-skip-permissions for this folder"
- If dangerouslySkipPermissions is on → "Disable --dangerously-skip-permissions for this folder"
- "Edit global defaults" (always shown)
- "Reset this folder to global defaults" (only if a directory override exists)
- "Done (no changes)"

## Step 4 — Apply the selected change

### Activate for this folder
```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" set-enabled true "$PWD"
```

### Deactivate for this folder
```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" set-enabled false "$PWD"
```

### Enable --dangerously-skip-permissions for this folder
Before running this, warn the user:

> "WARNING: When enabled, the next resume-session.sh will launch Claude with --dangerously-skip-permissions, which bypasses all tool permission prompts. This is safe for personal/trusted projects but should not be used on shared or untrusted codebases."

Then ask for explicit confirmation before proceeding. If confirmed:

```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" set-permissions true "$PWD"
```

### Disable --dangerously-skip-permissions for this folder
```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" set-permissions false "$PWD"
```

### Edit global defaults
Show a sub-menu with:
- Toggle global enabled (true/false)
- Toggle global dangerouslySkipPermissions (true/false)

If the user wants to enable dangerouslySkipPermissions globally, show an explicit warning:

> "WARNING: Enabling --dangerously-skip-permissions globally means EVERY folder where you run Claude will resume without permission prompts. This is a broad setting — consider using per-folder settings instead."

Then ask for explicit confirmation. If confirmed:
```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" set-permissions true
```

### Reset this folder to global defaults
```bash
python3 "$CLAUDE_PLUGIN_ROOT/scripts/manage.sh" reset "$PWD"
```

## Step 5 — Confirm and summarize

After any change, re-run `status "$PWD"` and show the updated state. Tell the user:

- What changed
- That the new setting will take effect on the next session start
- Where their resume-session.sh is (if it exists)

If the user chose "Done (no changes)", just say "No changes made." and stop.
