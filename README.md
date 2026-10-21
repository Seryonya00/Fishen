# Fishing Legend — Stage 1 prototype

A Godot 4 mobile fishing prototype: first-person shore movement, a simple cast/bite/hook/reel loop, catch and silver reward, and a starter shop. The current scene uses procedural primitives, so the project opens without downloaded art packs.

## Run in Godot
1. Install Godot 4.4.1 (standard build, not .NET).
2. Import `project.godot` and run the project.
3. Desktop test: WASD move, Shift run, right mouse drag look. Android touch: swipe on right side to look; buttons operate casting/hooking/reeling.

## APK build with GitHub Actions
1. Create a GitHub repository and upload/push this folder to its `main` branch.
2. Open **Actions → Build Android APK → Run workflow** (or push a project change).
3. Download the `FishingLegend-Android-APK` artifact from the completed workflow run.

The workflow builds a debug APK, not a Play Store release. For a signed release, configure a keystore and GitHub Actions secrets before distributing.

## Stage 1 scope / known prototype limits
- Single stylized pond, basic fishing timing loop, one catch type (carp/карась label), starter shop and local session state only.
- Save/load, robust joystick input, animated fish, real fishing rod/line, downloaded asset packs, and store economy are not implemented yet.
- CC0 asset sources checked: Poly Haven, Quaternius, Kenney. The runtime environment could browse their pages but could not resolve hosts for direct downloads; this stage therefore uses procedural meshes and does not bundle third-party assets.

## Asset sources for later stages
- Poly Haven: https://polyhaven.com (CC0)
- Quaternius: https://quaternius.com (check individual pack license page)
- Kenney: https://kenney.nl/assets (check pack license page)
