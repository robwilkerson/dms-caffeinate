---
name: local-development-setup
description: The running bar loads plugins from ~/.config/DankMaterialShell/plugins/<id>, so the repo must be symlinked there or edits have no effect
metadata:
  type: project
---

DMS loads plugins from `~/.config/DankMaterialShell/plugins/<id>`, **not** from wherever the
repo happens to live. For edits here to reach the running bar, that path must be a symlink to
this working directory:

```
~/.config/DankMaterialShell/plugins/caffeinate -> ~/Development/lookout-software/dms-caffeinate
```

If it is instead a real directory — which is what a normal plugin install produces — the bar
runs that independent copy and edits in the repo have **no effect at all**. This is a nasty
failure mode because nothing errors: reload and `dms restart` both succeed, and the old
behavior simply persists. It cost a full debugging cycle on 2026-08-27, where a changed
`--who` string kept respawning under its old value. The displaced install copy from that day
is parked at `~/.config/DankMaterialShell/plugins-backup/caffeinate`.

**Check this first** whenever a verified-correct QML edit doesn't show up in the bar:

```
ls -la ~/.config/DankMaterialShell/plugins/caffeinate
grep <the-string-you-changed> ~/.config/DankMaterialShell/plugins/caffeinate/<file>.qml
```

Swapping a real directory for a symlink changes the plugin's source path, so it needs a full
`dms restart` rather than a hot reload. See [[plugin-identity]] for the reload rules.

An agent shell here is sandboxed and **cannot see the user's session processes** — `pgrep`
returns only its own matches, which reads as a false "nothing is running". Inhibitor and
process state must be checked by the user with `systemd-inhibit --list`, never inferred from
an agent-side `pgrep`.

A `just develop` recipe to automate the symlink swap has been discussed but not built; the
repo deliberately has no build system, and all the `dms-*` siblings would want the same thing.
