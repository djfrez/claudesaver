#!/usr/bin/env python3
"""
claudesaver manage – config CRUD helper
Used by the /claudesaver skill and can be run directly from the terminal.

Usage:
  manage.sh status [dir]
  manage.sh set-enabled true|false [dir]
  manage.sh set-permissions true|false [dir]
  manage.sh reset [dir]
  manage.sh init
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
        return dict(DEFAULT_CONFIG)
    try:
        with open(CONFIG_PATH, "r") as f:
            cfg = json.load(f)
        if "directories" not in cfg:
            cfg["directories"] = {}
        return cfg
    except Exception:
        return dict(DEFAULT_CONFIG)


def save_config(config):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")
    os.chmod(CONFIG_PATH, 0o600)


def effective_settings(config, cwd):
    override = config.get("directories", {}).get(cwd)
    if override is not None:
        return {
            "enabled": override.get("enabled", config.get("enabled", True)),
            "dangerouslySkipPermissions": override.get(
                "dangerouslySkipPermissions",
                config.get("dangerouslySkipPermissions", False)
            ),
            "source": "directory-override"
        }
    return {
        "enabled": config.get("enabled", True),
        "dangerouslySkipPermissions": config.get("dangerouslySkipPermissions", False),
        "source": "global-default"
    }


def cmd_status(args):
    cwd = args[0] if args else os.getcwd()
    config = load_config()
    result = effective_settings(config, cwd)
    result["directory"] = cwd
    result["global"] = {
        "enabled": config.get("enabled", True),
        "dangerouslySkipPermissions": config.get("dangerouslySkipPermissions", False)
    }
    result["directoryOverride"] = config.get("directories", {}).get(cwd)
    print(json.dumps(result, indent=2))


def parse_bool(val):
    if val.lower() in ("true", "1", "yes"):
        return True
    if val.lower() in ("false", "0", "no"):
        return False
    print(f"Error: expected true or false, got: {val}", file=sys.stderr)
    sys.exit(1)


def cmd_set_enabled(args):
    if not args:
        print("Usage: manage.sh set-enabled true|false [dir]", file=sys.stderr)
        sys.exit(1)
    value = parse_bool(args[0])
    cwd = args[1] if len(args) > 1 else None
    config = load_config()
    if cwd:
        if cwd not in config["directories"]:
            config["directories"][cwd] = {}
        config["directories"][cwd]["enabled"] = value
        print(json.dumps({"set": "directory", "directory": cwd, "enabled": value}))
    else:
        config["enabled"] = value
        print(json.dumps({"set": "global", "enabled": value}))
    save_config(config)


def cmd_set_permissions(args):
    if not args:
        print("Usage: manage.sh set-permissions true|false [dir]", file=sys.stderr)
        sys.exit(1)
    value = parse_bool(args[0])
    cwd = args[1] if len(args) > 1 else None
    config = load_config()
    if cwd:
        if cwd not in config["directories"]:
            config["directories"][cwd] = {}
        config["directories"][cwd]["dangerouslySkipPermissions"] = value
        print(json.dumps({"set": "directory", "directory": cwd, "dangerouslySkipPermissions": value}))
    else:
        config["dangerouslySkipPermissions"] = value
        print(json.dumps({"set": "global", "dangerouslySkipPermissions": value}))
    save_config(config)


def cmd_reset(args):
    cwd = args[0] if args else os.getcwd()
    config = load_config()
    if cwd in config.get("directories", {}):
        del config["directories"][cwd]
        save_config(config)
        print(json.dumps({"reset": cwd, "status": "removed directory override"}))
    else:
        print(json.dumps({"reset": cwd, "status": "no override found, nothing changed"}))


def cmd_init(_args):
    if not os.path.exists(CONFIG_PATH):
        save_config(DEFAULT_CONFIG)
        print(json.dumps({"init": "created", "path": CONFIG_PATH}))
    else:
        print(json.dumps({"init": "already exists", "path": CONFIG_PATH}))


COMMANDS = {
    "status": cmd_status,
    "set-enabled": cmd_set_enabled,
    "set-permissions": cmd_set_permissions,
    "reset": cmd_reset,
    "init": cmd_init,
}


def main():
    args = sys.argv[1:]
    if not args or args[0] not in COMMANDS:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    COMMANDS[args[0]](args[1:])


if __name__ == "__main__":
    main()
