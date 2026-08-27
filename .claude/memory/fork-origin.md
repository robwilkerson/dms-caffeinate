---
name: fork-origin
description: This plugin began as a fork of hthienloc/dms-caffeine and is now an independent project; upstream tracking was deliberately abandoned
metadata:
  type: project
---

Caffeinate started as a fork of **`hthienloc/dms-caffeine`** (author "Loc Huynh"), a DankMaterialShell widget that keeps the screen awake. `origin` is `robwilkerson/dms-caffeinate`.

**Independence (2026-08-26):** the `upstream` remote was removed and upstream tracking abandoned. This is now an independent project that happens to share ancestry, not a fork kept in sync. Do not re-add an upstream remote, propose changes upstream, or hold back a change because it would be awkward to contribute back; those constraints no longer apply.

The GitHub repo was renamed `dms-caffeine` → `dms-caffeinate` the same day, matching the plugin id. GitHub still lists it as a fork of `hthienloc/dms-caffeine`; leaving the fork network is a manual GitHub action that has not been done.

**What that leaves behind:**
- `LICENSE` carries the original copyright. Attribution obligations survive independence, so leave it in place and keep the README's credit to the original project.
- `master` on `origin` is a leftover clean mirror of the old upstream default branch. It is no longer maintained as a mirror and nothing should be merged from it. It has not been deleted; deleting it is a separate call.
- Several `origin` branches (`explore/scaling-without-ring`, `feat/visible-idle-ring`, `fix/scale-bar-pill-to-bar-config`, `fix/smooth-progress-ring`) exist only because they were once offered as upstream pull requests. They are inert history now.

Divergence from the ancestor covers plugin identity ([[plugin-identity]]) and the bar-pill countdown ring ([[bar-pill-ring-design]]).
