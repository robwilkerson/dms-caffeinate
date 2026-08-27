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
- `CaffeineWidget.qml:12` — `pluginId: "caffeine"`.

**Known issue:** that last one is a real mismatch, not a deliberate choice. The rebrand commit `9d15b97` changed `plugin.json` and `CaffeineSettings.qml` but missed `CaffeineWidget.qml`, so the settings pane persists under `caffeinate` while the widget's `savePluginState`/`loadPluginState` calls (`expiration`, `selectedDuration`) persist under `caffeine`. Changing it will orphan any state already stored under the old key.

File and type names still say `Caffeine*` throughout. Only the plugin id and display name were rebranded; renaming the QML files would break `plugin.json`'s `component`/`settings` paths for no gain.

**Reloading after a change.** `dms ipc call plugins reload <pluginId>` and `dms ipc call plugin-scan rescan <pluginId>` both require the id argument and only hot-swap QML; neither re-reads `plugin.json`. So QML-only edits take `dms ipc call plugins reload caffeinate`, but any change to `plugin.json` needs `dms restart` (an in-place reload, no logout), which re-reads every manifest. `dms restart` is the safe default when unsure. These are interactive session commands and must run in the real Wayland session, not an agent sandbox.
