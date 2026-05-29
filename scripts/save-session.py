#!/usr/bin/env python3
"""
claudesaver – SessionStart hook
Reads session info from stdin JSON, writes resume-session.sh to the working directory.
Always exits 0 — never blocks session startup.
"""
import json
import os
import sys

CONFIG_DIR = os.path.expanduser("~/.claude/claudesaver")
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.json")

DEFAULT_CONFIG = {
    "enabled": True,
    "dangerouslySkipPermissions": False,
    "directories": {}
}


def load_config():
    if not os.path.exists(CONFIG_PATH):
        os.makedirs(CONFIG_DIR, exist_ok=True)
        save_config(DEFAULT_CONFIG)
        return DEFAULT_CONFIG
    try:
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    except Exception:
        return DEFAULT_CONFIG


def save_config(config):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=2)
    os.chmod(CONFIG_PATH, 0o600)  # owner read/write only


def effective_settings(config, cwd):
    """Resolve settings for cwd, falling back to global defaults."""
    override = config.get("directories", {}).get(cwd)
    if override is not None:
        return {
            "enabled": override.get("enabled", config.get("enabled", True)),
            "dangerouslySkipPermissions": override.get(
                "dangerouslySkipPermissions",
                config.get("dangerouslySkipPermissions", False)
            )
        }
    return {
        "enabled": config.get("enabled", True),
        "dangerouslySkipPermissions": config.get("dangerouslySkipPermissions", False)
    }


def ensure_gitignored(cwd):
    """Add /resume-session.sh to .gitignore if this is a git repo and not already ignored."""
    git_dir = os.path.join(cwd, ".git")
    if not os.path.exists(git_dir):
        return

    gitignore_path = os.path.join(cwd, ".gitignore")
    entry = "/resume-session.sh"

    if os.path.exists(gitignore_path):
        with open(gitignore_path, "r") as f:
            content = f.read()
        lines = [l.strip() for l in content.splitlines()]
        if entry in lines or "resume-session.sh" in lines:
            return
        with open(gitignore_path, "a") as f:
            if content and not content.endswith("\n"):
                f.write("\n")
            f.write("\n# claudesaver – session resume script (contains session ID)\n")
            f.write(entry + "\n")
    else:
        with open(gitignore_path, "w") as f:
            f.write("# claudesaver – session resume script (contains session ID)\n")
            f.write(entry + "\n")


def write_resume_script(cwd, session_id, dangerous):
    script_path = os.path.join(cwd, "resume-session.sh")
    lines = [
        "#!/bin/bash",
        "# claudesaver: resume script — DO NOT COMMIT (contains session ID)",
    ]
    if dangerous:
        lines += [
            "# WARNING: --dangerously-skip-permissions bypasses all tool permission prompts.",
            "# Only use this on trusted codebases you own.",
        ]
    lines += [
        f"# Session dir: {cwd}",
        "",
    ]
    cmd = f"claude --resume {session_id}"
    if dangerous:
        cmd += " --dangerously-skip-permissions"
    lines.append(cmd)
    lines.append("")

    with open(script_path, "w") as f:
        f.write("\n".join(lines))
    os.chmod(script_path, 0o700)  # owner-execute only


def main():
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
        session_id = data.get("session_id", "")
        cwd = data.get("cwd", os.getcwd())

        if not session_id:
            print(json.dumps({"continue": True, "suppressOutput": True}))
            return

        config = load_config()
        settings = effective_settings(config, cwd)

        if not settings["enabled"]:
            print(json.dumps({"continue": True, "suppressOutput": True}))
            return

        dangerous = settings["dangerouslySkipPermissions"]
        write_resume_script(cwd, session_id, dangerous)
        ensure_gitignored(cwd)

    except Exception:
        pass  # Never block session startup

    print(json.dumps({"continue": True, "suppressOutput": True}))


if __name__ == "__main__":
    main()
