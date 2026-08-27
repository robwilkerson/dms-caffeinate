# Caffeinate

Keep your screen awake and prevent idle sleep with a single click on your DankBar.

<img src="screenshot.png" width="300" alt="Screenshot">

## About this fork

Caffeinate is a personal fork of [Caffeine](https://github.com/hthienloc/dms-caffeine) by [hthienloc](https://github.com/hthienloc). They did the hard work; I just adjusted the aesthetics to my own taste: sizing the bar pill to the bar's thickness and scale, a smoother countdown ring, and a subtle idle-state ring.

The plugin `id` was renamed from `caffeine` to `caffeinate` so this fork can be installed alongside the original without either shadowing the other. The two have since diverged and develop independently.

## Install

Clone into your DMS plugins directory:
```bash
git clone https://github.com/robwilkerson/dms-caffeinate ~/.config/DankMaterialShell/plugins/caffeinate
```

## Features

- **DankBar Widget**: Click the coffee icon pill to manage screen stay-awake / sleep inhibition.
- **Control Center Integration**: View active status/remaining time and quickly select presets or custom durations from the Control Center.
- **Timed Sessions**: Choose from predefined presets or enter a custom duration (in minutes).
- **App Automation**: Auto-activate when specific media players or meeting tools are open.
- **Full Screen Awareness**: Automatically stay awake when any window is full-screen.
- **Battery Integration**: Automatically disable stay-awake when battery level drops below a configurable threshold to save power.
- **Deactivate on Manual Lock**: Disable stay-awake automatically if the screen is locked manually.

## Usage

| Action | Result |
|--------|--------|
| Left click | Open the duration picker popout (select presets or enter custom minutes) |
| Right click | Quick toggle stay-awake (activates with default duration, or deactivates/resets if active) |

## TODO / Roadmap

- [x] **Timed Sessions:** Predefined timers or custom duration options.
- [x] **Status Indicator:** Show remaining time in the bar for timed sessions.
- [x] **App Automation:** Auto-activate for specific apps (Media players, Meeting tools).
- [x] **Full Screen Awareness:** Stay awake automatically when any window is full-screen.
- [x] **Battery Integration:** Automatically disable when battery levels are low.
- [x] **Deactivate on Manual Lock:** Automatically disable stay-awake if the screen is locked manually.
- [ ] **Custom Presets Manager:** Save typed custom durations into persistent presets.

## License

GPL-3.0
