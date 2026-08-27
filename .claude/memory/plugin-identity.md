---
name: plugin-identity
description: The plugin id is "caffeinate", which files carry it, the known CaffeineWidget.qml mismatch, and how DMS reloads a changed plugin
metadata:
  type: project
---

DMS keys plugins by the `id` in `plugin.json`. This project uses **`caffeinate`** (name "Caffeinate"), chosen so it could be installed alongside the ancestor project's `caffeine` without either shadowing the other. See [[fork-origin]].

**Where identity lives:**
- `plugin.json` — `id`, `name`, `author`, `version`.
- `CaffeineSettings.qml:9` — `pluginId: "caffeinate"`.
- `CaffeineWidget.qml:12` — `pluginId: "caffeinate"`.

Both `pluginId` values must stay in sync. `PluginComponent.qml:96` resolves settings as
`pluginData = SettingsData.getPluginSettingsForPlugin(pluginId)`, so a mismatch doesn't
merely split persisted state — it silently disconnects the settings pane from the widget.
That is exactly what happened between rebrand commit `9d15b97` (which missed the widget)
and the 2026-08-27 fix: every control in the pane wrote to `caffeinate` while the widget
read `caffeine`, so the whole settings UI was inert with no error anywhere.

File and type names still say `Caffeine*` throughout. Only the plugin id and display name were rebranded; renaming the QML files would break `plugin.json`'s `component`/`settings` paths for no gain. All other `caffeine`/`Caffeine` identifiers (properties, functions, `Proc.runCommand` handles) were renamed to `caffeinate`/`Caffeinate` on 2026-08-27.

**Inhibitor identity.** The `systemd-inhibit --who` string is `Caffeinate` (and `Caffeinate Auto`
for the automation path), matched by `pgrep`/`pkill -f "Caffeinate"`. It was `DMS Caffeine`,
identical to the ancestor plugin's, so running both meant each one's `pkill` tore down the
other's inhibitor. The `DMS ` prefix was never a shell convention — DMS core doesn't shell out
to `systemd-inhibit` at all (`SessionService.qml` keeps `idleInhibited` as a flag routed
through the Go backend), and `systemd-inhibit(1)` describes `--who` as a short human-readable
application name. Renaming this strands any inhibitor already running under the old name until
the next `dms restart`.

**Reloading after a change.** `dms ipc call plugins reload <pluginId>` and `dms ipc call plugin-scan rescan <pluginId>` both require the id argument and only hot-swap QML; neither re-reads `plugin.json`. So QML-only edits take `dms ipc call plugins reload caffeinate`, but any change to `plugin.json` needs `dms restart` (an in-place reload, no logout), which re-reads every manifest. `dms restart` is the safe default when unsure. These are interactive session commands and must run in the real Wayland session, not an agent sandbox.
