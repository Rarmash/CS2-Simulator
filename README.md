# CS2 Simulator

[![Release](https://img.shields.io/github/v/release/Rarmash/CS2-Simulator?display_name=tag)](https://github.com/Rarmash/CS2-Simulator/releases)
[![Release Build](https://img.shields.io/github/actions/workflow/status/Rarmash/CS2-Simulator/release.yml?label=release%20build)](https://github.com/Rarmash/CS2-Simulator/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Web-4EAA25)](https://github.com/Rarmash/CS2-Simulator/releases)

Counter-Strike 2 container opening, collectible opening, glossary, and Trade-Up simulator built with Flutter and Dart.

The project focuses on reproducing CS2-style opening behavior, supporting more and more CS2 collectible content, and keeping the local item database generated from external data in a reproducible way.

## Disclaimer

This project is an unofficial fan-made simulator and is not affiliated with Valve.

Counter-Strike, Counter-Strike 2, item names, icons, images, and other related game assets are trademarks or property of their respective owners.

Unless explicitly stated otherwise, the repository license applies to the source code of this project and does not automatically grant rights to third-party game content, trademarks, or externally sourced assets or data.

## Features

- Case opening with roulette animation
- Optional X-Ray opening mechanic
- Souvenir packages with tournament-based dates
- Operation and Armory reward collections
- Legacy operation collections
- Sticker capsules
- Sticker collections
- Collectible pins capsules
- Music Kit Boxes, including `StatTrak™` music kits
- Agent collections
- Graffiti boxes
- Patch packs and patch collections
- Item glossary hub with dedicated screens for skins and collectibles
- Trade-Up simulator

## Tech Stack

- Flutter
- Dart
- Local JSON assets for all generated content
- Dart-based importer for containers, skins, stickers, pins, music kits, agents, graffiti, patches, and collection metadata

## Project Structure

- [lib/](lib) application code
- [assets/data/](assets/data) generated JSON data
- [assets/cases/](assets/cases) container images
- [assets/skins/](assets/skins) skin images
- [assets/stickers/](assets/stickers) sticker images
- [assets/pins/](assets/pins) pin images
- [assets/music_kits/](assets/music_kits) music kit images
- [assets/agents/](assets/agents) agent images
- [assets/graffiti/](assets/graffiti) graffiti images
- [assets/patches/](assets/patches) patch images
- [tool/import_cs_data.dart](tool/import_cs_data.dart) main importer entrypoint
- [tool/prune_generated_assets.dart](tool/prune_generated_assets.dart) cleanup tool for orphaned generated assets

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK

The project currently targets Dart `^3.11.3`.

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

## Releases

Prebuilt builds are published on the GitHub Releases page.

- [Latest release](https://github.com/Rarmash/CS2-Simulator/releases/latest)
- [All releases](https://github.com/Rarmash/CS2-Simulator/releases)

## Data Import

The app uses generated local JSON files and image assets. If you want to rebuild them:

```bash
dart run tool/import_cs_data.dart
```

Compression modes:

```bash
dart run tool/import_cs_data.dart --compression=fast
dart run tool/import_cs_data.dart --compression=max-compress
```

- `fast` is the default mode and is intended for normal development work
- `max-compress` is intended for rare clean release rebuilds

After a large migration or a clean import, you can remove orphaned generated assets:

```bash
dart run tool/prune_generated_assets.dart
```

## Notes About Generated Assets

- Existing generated assets are not overwritten during normal imports
- The importer stores the actual generated extension, including `.webp` where applicable
- Container dates are resolved locally instead of trusting API sale dates
- Supported container types fail the import if a hardcoded release date is missing
- Generated assets can be rebuilt in `fast` or `max-compress` mode depending on whether you are doing normal development or a release rebuild

## Typical Workflow

1. Run `flutter pub get`
2. Run `dart run tool/import_cs_data.dart`
3. Optionally run `dart run tool/prune_generated_assets.dart`
4. Launch the app with `flutter run`

## Data Source

The importer consumes public CS data from ByMykel's API and then normalizes it locally for simulator-specific behavior.

## License

The source code in this repository is licensed under `AGPL-3.0`.

## Status

The project is actively evolving, with current work focused on:

- expanding simulator coverage for CS2 collectible content
- continuing UI/codebase refactoring to reduce duplicated screen logic
- reducing release size through better asset compression
- preparing a more reusable foundation for future non-skin glossaries

## Roadmap

### v0.10

- Trade-Up rewrite and UI cleanup
- Charm support
- Unified handling of regular and StatTrak™ Music Kits as one grouped item
- Broader simulator accuracy pass across more container types
- Better browsing and glossary coverage for non-skin content

### Future

- Skin pattern and finish seed support for items where patterns matter
- Cleaner navigation across containers, collections, and collectibles
- Music Kit preview playback if a reliable audio source is available
- Optional China / Perfect World visual mode if a reliable alternate asset source is available
