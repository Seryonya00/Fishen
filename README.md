# Fishing Legend

A mobile-first 3D fishing prototype made with **Godot 4.7.2**.

## Android APK build

GitHub Actions builds the APK on every push to `main` and on manual dispatch.

1. Open the repository's **Actions** tab.
2. Select **Build Android APK** and open the latest run.
3. When the run succeeds, download the artifact named `FishingLegend-Android-APK`.

The workflow installs Godot 4.7.2 and its matching export templates, Java 17, and Android SDK packages. It runs a headless project import/parse step before exporting and checks the APK archive before uploading it.

## Current prototype

- Procedural first-person lakeside world, pier, trees, reeds, and a small village.
- Touch movement and swipe look controls.
- Casting, bite timing, hooking, tension-based fish fighting, catch log, selling fish, silver, levels, and local save.
- Android ARM64 debug APK preset.

## Limitations

This is an early playable prototype, not a complete fishing simulator yet. More fishing gear, locations, fish models/animations, weather, sound, quests, and device testing remain to be implemented. A green workflow and valid APK archive are required before considering the build verified; install the artifact on a physical Android device to test actual gameplay.
