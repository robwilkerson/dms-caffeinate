# Caffeinate

A DankMaterialShell (DMS) bar widget that keeps the screen awake and prevents idle sleep.
Left click opens a duration picker; right click quick-toggles. The bar pill draws a
countdown ring around a `local_cafe` glyph.

Began as a fork of `hthienloc/dms-caffeine` and is now independent — no upstream remote,
no contributions flow back. See `.claude/memory/fork-origin.md`.

## Stack

QML for Quickshell/DMS (Qt 6). No build system, no package manager, no dependency
manifest — DMS loads the QML directly. `scripts/i18n.py` is standalone Python 3
(stdlib only) for translation tooling.

- `CaffeinateWidget.qml` — the widget: bar pill, popout, automation, all state
- `CaffeinateSettings.qml` — the settings pane, loaded via `plugin.json`'s `settings` key
- `CaffeinateMark.qml` — the mug glyph, drawn from Lucide's `coffee` path data
- `RadialProgressRing.qml` — the countdown ring
- `dms-common/` — shared DMS UI components (`SettingsCard`, `ToggleSettingPlus`, …)
  carried by several DMS plugins, not authored for this one. Don't refactor it to suit
  this plugin; keep it swappable.

The canonical DMS plugin API reference is `/usr/share/quickshell/dms/PLUGINS/README.md`.
Read it before guessing at `PluginComponent` properties or `Theme` helpers.

## Verifying a change

There are no tests and no CI, and QML errors surface only at load time. Never claim a
visual or behavioral change works — you cannot see the bar. Finish every change by
telling the user which command to run and what to look for, then wait:

- QML-only edits: `dms ipc call plugins reload caffeinate`
- Any `plugin.json` change (id, name, version): `dms restart`

Both require the id argument, and neither re-reads `plugin.json`, so `dms restart` is the
safe default. These run in the user's Wayland session, not an agent shell.

If a correct-looking edit doesn't change the bar's behavior, check that
`~/.config/DankMaterialShell/plugins/caffeinate` is a symlink to this repo before debugging
anything else. A real directory there means the bar is running a different copy and your edits
never load. See `.claude/memory/local-development-setup.md`.

## Conventions

- Plugin `id` is `caffeinate`, and the `pluginId` in both `CaffeinateWidget.qml` and
  `CaffeinateSettings.qml` must match it. A mismatch disconnects the settings pane from the
  widget with no error anywhere. See `.claude/memory/plugin-identity.md`.
- Nothing is named `Caffeine*` any more — files, types, and identifiers are all
  `Caffeinate*`. Renaming a QML file means updating `plugin.json`'s `component`/`settings`
  paths in the same commit.
- User-facing strings go through `I18n.tr()`. After adding one, run
  `python3 scripts/i18n.py extract`. Skip `translate` — it machine-translates via Google
  and the shipped poexports are deliberately left stale. The brand name stays unlocalized.
  (The script's docstring says "dms-stopwatch" — it was copied from another plugin.)
- The bar mark is deliberately austere: no label, fixed footprint, ring only while a timed
  session counts down. See `.claude/memory/bar-pill-ring-design.md`.

Work is tracked in GitHub Issues on `robwilkerson/dms-caffeinate`.

## Related Projects

Read on-demand; never preload at session start.

- **Sibling** `~/Development/lookout-software/dms-*` — every DMS plugin repo in this
  parent directory (the set grows; glob it, don't assume a fixed list). They are
  independent plugins that share tooling, vendored components, and one runtime.
  Blast-radius triggers: changes to anything under `dms-common/`; changes to
  `scripts/i18n.py` or the translation file layout; a new plugin `id` that could collide
  with an existing one; and any discovery about the DMS plugin API worth carrying across.
  Surface the impact and suggest the carry-over; never edit another repo without being asked.

- **Sibling** `~/dotfiles` — holds the live DMS config that loads and configures this widget.
  Blast-radius triggers: changes to the plugin `id` in `plugin.json`; changes to any
  `pluginId` in QML; adding, renaming, or removing a persisted settings key
  (`savePluginData` / `savePluginState` / `PluginSettings` properties). Each requires a
  matching edit to `DankMaterialShell.linux/.config/DankMaterialShell/plugin_settings.json`
  (per-plugin state) or `settings.json` (bar widget enablement), both keyed by plugin id.
  Surface the impact; never edit dotfiles without being asked.
