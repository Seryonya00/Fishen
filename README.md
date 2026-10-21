# Fishing Legend

A mobile-first 3D fishing game prototype built with Godot 4.

## Current vertical slice
- First-person lakeside scene generated procedurally (no paid assets)
- Touch-friendly movement/look and fishing controls
- Casting, bite timing, hook setting, fish fight/tension, catch log, sell catch and silver progression
- Equipment stats and simple tackle shop
- Save/load with `user://savegame.json`
- Android APK build workflow via GitHub Actions

## Build locally
1. Install Godot 4.3+ and Android export templates.
2. Open `project.godot` in Godot.
3. Configure Android SDK/JDK in Editor Settings and Android export preset.
4. Export Android APK.

## CI build
Push to `main` or run **Actions → Build Android APK**. The workflow installs Godot Android export templates, creates a temporary Android export preset, and uploads the APK as a workflow artifact.

## Assets and licenses
The initial scene uses procedural geometry so it starts without downloads. Asset sources to integrate are [Poly Haven](https://polyhaven.com/) (CC0), [Quaternius](https://quaternius.com/) (check each pack's current license; many are CC0), and [Kenney](https://kenney.nl/) (check each asset pack's license). Do not redistribute source asset packs as standalone content.

## Scope
This is a playable prototype/vertical slice, not yet the full feature list: additional locations, fish species/animations, boats, winter fishing, quests, online leaderboards and monetization require future iterations and device testing.
