# FiakKere - Offline-First Bible Meditation App

[![State: watch_it](https://img.shields.io/badge/State-watch__it-purple?style=for-the-badge)](https://pub.dev/packages/watch_it)
[![Logic: command_it](https://img.shields.io/badge/Logic-command__it-blueviolet?style=for-the-badge)](https://pub.dev/packages/command_it)
[![Collections: listen_it](https://img.shields.io/badge/Collections-listen__it-darkgreen?style=for-the-badge)](https://pub.dev/packages/listen_it)

FiakKere is an open-source, offline-first mobile application developed with Flutter, dedicated to
deep, focused scripture meditation.

The app features a continuous looping audio playback loop that combines cross-referenced Bible
verses with on-device Text-to-Speech (TTS) to provide an immersive, distraction-free environment for
spiritual reflection.

## Concept Behind FiakKere

In the original Hebrew and Greek contexts, biblical meditation is illustrated by the image of a
ruminant animal chewing its cud—bringing back food already eaten to digest it repeatedly until every
nutrient is fully extracted.

**FiakKere** is derived from the Ibibio language (indigenous to southeastern Nigeria). "**Fiak**"
means to return or do again, and "**Kere**" means to _think_, _meditate_, or _ponder_. Together, *
*FiakKere** means "_to think again_" or "_to return to the thought_," translating this profound
ancient metaphor of spiritual rumination into a modern digital experience.

## Key Features

- **Continuous Audio Playback Loops**: Create dedicated scripture meditation playlists that play
  smoothly even when the device screen is locked or the app is backgrounded.
- **Dynamic Verse Injection**: Utilizing the **Treasury of Scripture Knowledge (TSK)**, the app
  automatically tracks your reading context and inserts relevant cross-referenced verses directly
  into your active playback loop for continuous, thematic meditation.
- **On-Device Text-to-Speech (TTS)**: Completely native voice synthesis avoids large file downloads,
  keeps the app size minimal, and preserves user privacy.
- **Offline-First Local Storage**: Powered by a pre-built, compressed NoSQL database that
  initializes instantly on first launch and requires no internet connection or cloud user
  authentication.

## Architecture & Technical Stack

FiakKere utilizes a highly scannable
*[Pragmatic Flutter Architecture (PFA)](https://blog.burkharts.net/practical-flutter-architecture)*
powered by the `flutter_it` toolkit. This structure isolates responsibilities into clean,
feature-driven boundaries:

| Layer    | Responsibility                                                                       | Associated Dependencies                                   |
|----------|--------------------------------------------------------------------------------------|-----------------------------------------------------------|
| Services | Direct communication with external platform APIs and local storage boundaries.       | `objectbox`, `just_audio`, `audio_service`, `flutter_tts` |
| Managers | Core business logic execution, state mutation, and application lifecycle management. | `get_it`, `command_it`, `listen_it`                       |
| Views    | Declarative UI layer featuring highly optimized, reactive widget rebuilds.           | `watch_it`                                                |

## Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  get_it: ^7.6.0                # Service location & loose composition
  watch_it: ^1.0.0              # Reactive widget state tracking
  command_it: ^1.0.0            # Encapsulated asynchronous actions
  listen_it: ^1.0.0             # Reactive collection and stream management
  objectbox: ^4.0.0             # High-speed NoSQL local database bindings
  objectbox_flutter_libs:       # Platform binaries for ObjectBox engine
  just_audio: ^0.9.40           # Gapless audio queue playback engine
  audio_service: ^0.18.12       # Native OS background audio controls
  flutter_tts: ^4.0.2           # Cross-platform text-to-speech synthesis
  path_provider: ^2.1.2         # Local system file directory lookups
  shared_preferences: ^2.2      # Lightweight persistent configuration storage
```

_(See TRD.md for full architectural design principles and future V2 scalability plans)._

## Project Structure

The project directory is structured by feature rather than generic technical layers to maximize
cohesion and onboarding speed:

```
lib/
  _shared/                 # Cross-cutting architecture layers
    services/              # ObjectBox, TTS, and Audio system engines
    models/                # Centralized ObjectBox database entities
  features/                # Encapsulated product modules
    scripture/             # Search engine and verse browser UI
    playlist/              # User meditation list management (CRUD)
    session/               # Audio loop tracking and dynamic verse injectors
    settings/              # TTS playback speeds and visual configurations
  locator.dart             # Application composition root
  main.dart                # Hardware bindings and entry point
```

## Data & Copyright Strategy

To support lightning-fast offline execution with zero hosting or licensing liabilities, FiakKere
operates exclusively with public domain material:

- **Scripture Text**: Bundled with the modern, public-domain **World English Bible (WEB)**
  translation.
- **Cross-References**: Leverages flat lookup mapping tables sourced from the historic **Treasury of
  Scripture Knowledge (TSK)**.
- **Database Seeding**: On development machines, a standalone tool builds the ObjectBox data store
  files (`tool/build_bible_db.dart`). This file is bundled as a compressed asset file (
  `assets/bible_db.zip`) and extracted locally into client application storage upon initial boot to
  ensure immediate startup performance.

## Getting Started

### Prerequisites

- Flutter SDK (Stable Channel)
- Dart SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/gettoknowdavid/fiakkere-meditation-bible-app.git
   cd fiakkere-meditation-bible-app
   ```

2. Fetch application dependencies:
   ```bash
   flutter pub get
   ```

3. Generate the required local model files for the ObjectBox NoSQL storage engine:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Execute the software on a connected device or hardware emulator:
   ```bash
   flutter run
   ```

## License

Distributed under the permissive MIT License. See the LICENSE file for additional details.