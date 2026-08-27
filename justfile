# Caffeinate — Command Runner
# Run `just` or `just --list` to see available commands.
#
# There is no build step: DMS loads the QML directly from disk. So most recipes
# here are either (a) making the running bar point at this working tree instead
# of an installed copy, or (b) checking invariants that fail silently — a
# pluginId mismatch or a stale install copy produces no error, just a widget
# that quietly ignores you.
#
# The `dms` recipes must run in your Wayland session. They will not work from a
# detached shell or an agent sandbox.

PLUGIN_ID := "caffeinate"

# --unsorted lists recipes and groups in source order rather than alphabetically,
# so they read setup -> daily loop -> checks instead of C-D-S-U-i.

# Show available commands
default:
    @just --list --unsorted

# ══════════════════════════════════════════════════════════════════════════════
# Setup
# ══════════════════════════════════════════════════════════════════════════════

# Check that required tooling is present (idempotent)
[group('Setup')]
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔍 Checking required tools..."
    MISSING=0
    command -v dms >/dev/null 2>&1 || { echo "❌ dms not found (DankMaterialShell)"; MISSING=1; }
    command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found (needed for scripts/i18n.py)"; MISSING=1; }
    command -v git >/dev/null 2>&1 || { echo "❌ git not found"; MISSING=1; }
    [ $MISSING -eq 0 ] && echo "✅ All required tools found"
    echo ""
    echo "🔍 Checking optional tools..."
    command -v systemd-inhibit >/dev/null 2>&1 || echo "⚪ systemd-inhibit not found (the plugin itself needs it, as does 'just inhibitors')"
    echo ""
    just status
    echo ""
    echo "Next step: 'just develop start' to point the running bar at this working tree."

# ══════════════════════════════════════════════════════════════════════════════
# Dev
# ══════════════════════════════════════════════════════════════════════════════

# Point the bar at this tree (start) or restore installed version (stop)
[group('Dev')]
develop action="start":
    #!/usr/bin/env bash
    set -euo pipefail
    PLUGINS="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
    TARGET="$PLUGINS/{{ PLUGIN_ID }}"
    BACKUP="$PLUGINS-backup/{{ PLUGIN_ID }}"
    REPO="$(git rev-parse --show-toplevel)"

    case "{{ action }}" in
      start)
        if [ -L "$TARGET" ] && [ "$(readlink -f "$TARGET")" = "$REPO" ]; then
            echo "✅ Already developing: $TARGET -> $REPO"
            exit 0
        fi

        mkdir -p "$PLUGINS"
        if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
            # A real directory here means the bar is running an installed copy
            # and would ignore every edit made in this tree. Move it, never
            # delete it: it may hold changes this tree does not.
            if [ -e "$BACKUP" ]; then
                echo "❌ Refusing to overwrite an existing backup at:" >&2
                echo "   $BACKUP" >&2
                echo "   Move or remove it first, then re-run." >&2
                exit 1
            fi
            mkdir -p "$(dirname "$BACKUP")"
            mv "$TARGET" "$BACKUP"
            echo "📦 Moved installed copy aside: $BACKUP"
        elif [ -L "$TARGET" ]; then
            rm "$TARGET"
        fi

        ln -s "$REPO" "$TARGET"
        echo "🔗 $TARGET -> $REPO"
        ;;

      stop)
        if [ ! -L "$TARGET" ]; then
            if [ -e "$TARGET" ]; then
                echo "❌ $TARGET is a real directory, not a dev symlink." >&2
                echo "   Refusing to touch it. Resolve by hand." >&2
                exit 1
            fi
            echo "⚪ Not developing: $TARGET does not exist"
            exit 0
        fi
        rm "$TARGET"
        if [ -e "$BACKUP" ]; then
            mv "$BACKUP" "$TARGET"
            echo "📦 Restored installed copy: $TARGET"
        else
            # Nothing was displaced when develop started, so removing the
            # symlink leaves the plugin uninstalled rather than reverted.
            echo "🔗 Removed dev symlink. No installed copy was displaced, so"
            echo "   {{ PLUGIN_ID }} is now absent from $PLUGINS."
        fi
        ;;

      *)
        echo "❌ Unknown action '{{ action }}'. Expected 'start' or 'stop'." >&2
        exit 1
        ;;
    esac

    echo ""
    echo "⚠️  The plugin's source path changed, so a hot reload is not enough."
    echo "    Run: just restart"

# Show whether the bar is running this tree or an installed copy
[group('Dev')]
status:
    #!/usr/bin/env bash
    set -euo pipefail
    PLUGINS="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
    TARGET="$PLUGINS/{{ PLUGIN_ID }}"
    REPO="$(git rev-parse --show-toplevel)"

    if [ ! -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        echo "⚪ Not installed: $TARGET does not exist"
    elif [ -L "$TARGET" ]; then
        RESOLVED="$(readlink -f "$TARGET")"
        if [ "$RESOLVED" = "$REPO" ]; then
            echo "✅ Developing this tree: $TARGET -> $RESOLVED"
        else
            echo "⚠️  Symlinked elsewhere: $TARGET -> $RESOLVED"
            echo "    This tree is $REPO — your edits will not load."
        fi
    else
        echo "⚠️  Installed copy (a real directory): $TARGET"
        echo "    Edits in this tree will NOT load. Run: just develop start"
    fi

# Hot-reload the QML (does not re-read plugin.json)
[group('Dev')]
reload:
    dms ipc call plugins reload {{ PLUGIN_ID }}

# Full DMS restart; required after any plugin.json change or a develop swap
[group('Dev')]
restart:
    dms restart

# ══════════════════════════════════════════════════════════════════════════════
# Checks
# ══════════════════════════════════════════════════════════════════════════════

# Verify the invariants that fail silently at runtime
[group('Checks')]
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 - <<'PY'
    import json, re, sys
    from pathlib import Path

    fail = 0
    def bad(msg):
        global fail
        fail = 1
        print(f"❌ {msg}")

    manifest = json.loads(Path("plugin.json").read_text())
    plugin_id = manifest["id"]
    print(f"plugin.json id: {plugin_id}")

    # Every referenced QML file must exist. A rename that misses the manifest
    # leaves the plugin unloadable, and a hot reload will not reveal it.
    for key in ("component", "settings"):
        rel = manifest.get(key)
        if not rel:
            continue
        path = Path(rel.removeprefix("./"))
        if path.exists():
            print(f"✅ {key}: {path}")
        else:
            bad(f"{key} points at a missing file: {path}")

    # Every pluginId must match the manifest id. PluginComponent resolves
    # settings by pluginId, so a mismatch silently disconnects the settings
    # pane from the widget with no error anywhere.
    for path in sorted(Path(".").glob("*.qml")):
        for m in re.finditer(r'pluginId:\s*"([^"]+)"', path.read_text()):
            found = m.group(1)
            if found == plugin_id:
                print(f"✅ {path.name}: pluginId {found}")
            else:
                bad(f"{path.name}: pluginId is {found!r}, expected {plugin_id!r}")

    # The inhibitor identity has to be spawned and matched under one name, or
    # deactivating silently leaves the inhibitor running.
    component = Path(manifest["component"].removeprefix("./"))
    if not component.exists():
        print("⏭  skipping inhibitor check: component file is missing")
    else:
        widget = component.read_text()
        who = set(re.findall(r'--who=([^"]+)', widget))
        matched = set(re.findall(r'"-f",\s*"([^"]+)"', widget))
        print(f"inhibitor --who: {sorted(who)}")
        print(f"pgrep/pkill patterns: {sorted(matched)}")
        ok = True
        for pattern in matched:
            unmatched = [w for w in who if pattern not in w]
            if unmatched:
                ok = False
                bad(f"pattern {pattern!r} will not match --who values {unmatched}")
        if ok and matched and who:
            print("✅ every --who value is matched by its pgrep/pkill pattern")

    sys.exit(fail)
    PY

# ══════════════════════════════════════════════════════════════════════════════
# i18n
# ══════════════════════════════════════════════════════════════════════════════

# Rebuild English translations
[group('i18n')]
extract:
    python3 scripts/i18n.py extract

# Show translation coverage per language
[group('i18n')]
coverage:
    @python3 scripts/i18n.py status

# ══════════════════════════════════════════════════════════════════════════════
# Utility
# ══════════════════════════════════════════════════════════════════════════════

# List active idle inhibitors
[group('Utility')]
inhibitors:
    @systemd-inhibit --list
