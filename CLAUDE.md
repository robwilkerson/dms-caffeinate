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

- `CaffeineWidget.qml` — the widget: bar pill, popout, automation, all state
- `CaffeineSettings.qml` — the settings pane, loaded via `plugin.json`'s `settings` key
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

## Conventions

- Plugin `id` is `caffeinate`. There is a known mismatch: `CaffeineWidget.qml:12` still
  says `pluginId: "caffeine"`, splitting persisted state across two keys. See
  `.claude/memory/plugin-identity.md` before touching either.
- File and type names stay `Caffeine*`. Only the id and display name were rebranded.
- User-facing strings go through `I18n.tr()`. After adding one, run
  `python3 scripts/i18n.py extract`, then `translate`. The brand name stays unlocalized.
  (The script's docstring says "dms-stopwatch" — it was copied from another plugin.)
- The bar-pill ring is unconditional and its idle opacity is `0.4` on purpose. Neither is
  a stray tweak. See `.claude/memory/bar-pill-ring-design.md`.

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
