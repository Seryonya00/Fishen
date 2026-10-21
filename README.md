# Fishing Legend

Mobile-first 3D fishing prototype built with Godot 4.3.

## Build Android APK

The GitHub Actions workflow at `.github/workflows/android.yml` builds a debug APK on every push to `main` and on manual dispatch.

1. Open the repository's **Actions** tab.
2. Select **Build Android APK**.
3. Open a successful run and download the `FishingLegend-Android-APK` artifact.

The workflow installs Java 17, Godot 4.3 with export templates, and Android SDK Platform 34 / Build Tools 34.0.0. It configures Godot's Android SDK and Java paths, validates the project, exports the APK, and checks that the APK archive is readable.

## Project layout

- `project.godot` — Godot project settings.
- `scenes/main.tscn` — main 3D scene.
- `scripts/main.gd` — procedural scene and mobile gameplay.
- `scripts/game.gd` — gameplay systems under development.
- `export_presets.cfg` — tracked Android debug export preset.
- `.github/workflows/android.yml` — CI validation and APK build.

## Current prototype

- Procedural first-person lakeside environment.
- Touch-friendly movement and fishing controls.
- Casting, bite timing, hooking, fish fighting, catch log and silver progression.
- Lightweight procedural assets; no paid asset dependencies.

This is a prototype, not yet a complete simulation of every feature in the design brief. A successful CI run confirms that the APK was exported and its archive is readable; install and test it on a physical Android device before publishing.
