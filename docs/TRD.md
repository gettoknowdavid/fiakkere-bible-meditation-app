# TRD.md — ScriptureFlow (Working Title)

**Version:** 1.0 (MVP)
**Status:** Draft — pending approval
**Owner:** Solo dev, Senior Flutter Architect role

---

## 1. Project Overview & Non-Functional Requirements

### 1.1 Mission

Ship a fast, offline-first Flutter app that lets a user browse Bible verses, build a meditation
playlist, set a timer,
and start a looped audio+text session that keeps playing when the device is locked — with
related-verse discovery woven
into the experience. Launch speed is the primary constraint. Every architectural decision below is
made in service of "
fewest moving parts that still deliver a delightful core loop."

### 1.2 Non-Functional Requirements (ranked)

| # | Requirement                      | Target                                                                                                                      | Rationale                                                                                                           |
|---|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| 1 | **Launch speed**                 | MVP shippable by a solo dev in a focused sprint                                                                             | This is the dominant constraint on every decision in this document                                                  |
| 2 | **Offline-first**                | Zero required network calls for the core loop (browse → playlist → session)                                                 | No backend to build/host/maintain; no auth; instant reliability                                                     |
| 3 | **App bundle size**              | Bundled Bible DB should be the single largest asset; keep total app size reasonable for mobile download                     | ObjectBox binary DB is compact; no audio files bundled (TTS generates on-device)                                    |
| 4 | **Background audio reliability** | Session audio must survive screen lock, backgrounding, and (within OS limits) app-switching                                 | This is the single feature most likely to make or break user trust in a meditation app                              |
| 5 | **Codegen discipline**           | No code-generation anywhere in the stack **except** ObjectBox's required `objectbox_model.g.dart` / `.g.dart` binding files | Keeps build times fast and the mental model simple; ObjectBox codegen is unavoidable and isolated to the data layer |
| 6 | **Cold-start time**              | App usable within ~1–2s of splash                                                                                           | ObjectBox opens fast; no heavy JSON parsing at runtime (DB ships pre-built)                                         |

### 1.3 Explicit Non-Goals (MVP)

Multiple translations, cloud sync/accounts, social features, premium cloud TTS voices, background
music/crossfading,
ML-based verse recommendations. All deferred to V2+ (see Section 7).

---

## 2. Product Strategy

### 2.1 Copyright Strategy — Text Sourcing

This is the highest-risk, non-technical part of the project and must be locked down before any UI
work begins.

- **Translation**: Ship with **WEB (World English Bible)** as the default bundled translation. WEB
  is public domain
  worldwide with no license restrictions, reads in modern English (better for a meditation/reading
  UX than KJV's archaic
  phrasing), and requires zero legal review.
- **Fallback option**: KJV is also fully public domain and can be offered as a bundled alternative
  later, but WEB is the
  MVP default.
- **Explicitly avoid**: ESV, NIV, NLT, NASB, and other modern translations — these are copyrighted
  and require licensing
  agreements (e.g., through Biblica/YouVersion) that are entirely out of scope for a fast MVP
  launch.
- **Cross-reference data**: Use the **Treasury of Scripture Knowledge (TSK)** dataset for "related
  verses." TSK is
  public domain, long-established, and available as flat verse-to-verse mapping data. This
  eliminates any need for an
  ML/embeddings-based recommendation system for MVP — it's a static lookup table.
- **Action item before Phase 0 coding starts**: source a specific WEB text dataset and TSK
  cross-reference dataset from
  a reputable open repository, and record the exact source + license confirmation in
  `/docs/data-sourcing.md`. Do not
  proceed to DB-building until this is confirmed in writing.

### 2.2 Audio Strategy — TTS Over Pre-Recorded

- Pre-recording ~31,000 verses is a non-starter: multi-gigabyte asset size, massive time cost, and
  separate copyright
  exposure even if the underlying text is PD (audio narrations are their own-copyrighted work).
- **MVP decision: on-device TTS via `flutter_tts`.** Zero hosting cost, zero bundle size impact,
  works fully offline,
  cross-platform (uses native iOS/Android TTS engines).
- Audio is **generated on first play and cached to local file storage**, keyed by verse ID +
  voice/locale settings, so a
  verse is only synthesized once per device.
- The `AudioPlayerService` is built behind a clean interface from day one specifically so a future
  premium cloud-TTS
  provider (ElevenLabs, Google Cloud TTS) can be swapped in post-launch without touching call
  sites — this is a
  deliberate seam, not speculative abstraction.

### 2.3 What This Strategy Buys Us

By combining a PD translation + static TSK cross-references + on-device TTS, the entire MVP requires
**zero backend
infrastructure, zero recurring costs, and zero licensing risk.** This is what makes "shortest path
to launch" actually
achievable for a solo dev.

---

## 3. System Architecture Overview

### 3.1 Architectural Style

**Pragmatic Flutter Architecture (PFA)** using the `flutter_it` construction set. Three layers per
feature:

- **Services** — wrap exactly one external boundary (ObjectBox, `flutter_tts`, `just_audio`/
  `audio_service`,
  `shared_preferences`). Stateless from the app's perspective; convert between external and internal
  data shapes. Never
  hold app state.
- **Managers** — own business logic and app state for a feature area (`ScriptureManager`,
  `PlaylistManager`,
  `SessionManager`, `SettingsManager`). Expose `ValueListenable`s and `Command`s. Never touched
  directly by widgets for
  mutation — only through Commands.
- **Views** — pages and widgets. Self-responsible: know what data they need, `watch()` it directly
  from Managers via
  `get_it`. Never call Services directly.

### 3.2 `flutter_it` Package Roles

| Package          | Role in ScriptureFlow                                                                                                                                                                                                                                                                                                                                                      |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`get_it`**     | Composition root / service locator. Every Service and Manager is registered as a lazy singleton in `locator.dart`. No widget ever constructs a Service or Manager directly — always `di<T>()`.                                                                                                                                                                             |
| **`watch_it`**   | UI reactivity. Views are `WatchingWidget`s that call `watch()` / `watchValue()` on Manager state, and `registerHandler()` for one-off side effects (e.g., "session complete" navigation).                                                                                                                                                                                  |
| **`command_it`** | All user-triggered async/sync actions (play, pause, stop, add-to-playlist, start-session) are `Command`s on Managers. Widgets bind to `command.isRunning` for loading state and never call Manager methods that aren't Commands for anything that touches external state.                                                                                                  |
| **`listen_it`**  | Reactive collections and composition. `SessionManager`'s active playback queue is a `ListNotifier<Verse>`; `currentVerse` is derived via `combineLatest` over the queue + current index. This is also the mechanism by which "dynamic injection" works: inserting into the reactive queue automatically propagates to both UI and the audio engine's mirrored source list. |

### 3.3 Core Reactive Data Flow (the "session loop")

1. `PlaylistManager` holds the user's saved verse selection (ObjectBox-backed, reactive via `Stream`
   query wrapped in a
   `ValueNotifier`).
2. On "Start Session," `SessionManager.startCommand` copies the playlist into `activeQueue` (
   `ListNotifier<Verse>`).
3. `AudioPlayerService` subscribes to `activeQueue` via `listen_it`'s `listen()` and mirrors
   additions/removals into
   `just_audio`'s `ConcatenatingAudioSource`, generating/fetching cached TTS audio per verse as
   needed.
4. If "Dynamic Play" is enabled (`SettingsManager`), on each verse completion `RelatedVerseInjector`
   queries TSK
   cross-references via `ScriptureManager`/ObjectBox and inserts a related verse into
   `activeQueue` — no manual wiring
   needed elsewhere, because everything downstream already reacts to the queue.
5. `SessionTimerDisplay` and `RelatedVersePanel` are separate small `WatchingWidget`s so a
   once-per-second timer tick
   doesn't rebuild the whole player page.

### 3.4 Why Not Riverpod for MVP

See Section 7. Short version: `flutter_it` has less ceremony, no required codegen outside ObjectBox,
and a gentler
solo-dev learning curve — the right trade for launch speed. The folder structure is intentionally
close enough to a
Clean Architecture layering that a future migration is a targeted rewrite of the Manager/Command
layer, not a full app
rewrite.

---

## 4. Core Dependencies

| Package                                | Purpose                                                                               | Notes                                                             |
|----------------------------------------|---------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| `get_it`                               | Service locator / DI                                                                  | Core of `flutter_it`                                              |
| `watch_it`                             | Reactive widget binding                                                               | Core of `flutter_it`                                              |
| `command_it`                           | Action/command pattern                                                                | Core of `flutter_it`                                              |
| `listen_it`                            | Reactive collections & ValueListenable operators                                      | Core of `flutter_it`                                              |
| `objectbox` + `objectbox_flutter_libs` | Local NoSQL storage — Bible text, cross-refs, playlists                               | **Only** codegen exception (`objectbox_model.g.dart`)             |
| `just_audio`                           | Gapless/looping audio playback engine                                                 | Builds the verse-audio queue via `ConcatenatingAudioSource`       |
| `audio_service`                        | OS-level background audio, lock-screen & notification controls                        | Required for the background-playback NFR                          |
| `flutter_tts`                          | On-device text-to-speech                                                              | Zero cost, zero bundle size, offline                              |
| `shared_preferences`                   | Simple key-value settings (dynamic-play toggle, default timer length, TTS voice/rate) | No need for ObjectBox here — settings aren't queried/related data |
| `path_provider`                        | Locate app document directory for cached TTS audio files                              | Standard utility, no architectural weight                         |

**Explicitly not included in MVP:** `dio`/`http` (no network calls in core loop), `riverpod`,
`drift`/`sqflite` (
superseded by ObjectBox per updated requirements), `workmanager`/`android_alarm_manager` (
audio_service's foreground
service is sufficient to keep the process alive during an active session).

---

## 5. ObjectBox Data Models

### 5.1 Design Principles

- Two logical groups of data: **read-only bundled Scripture data** (Verses, CrossReferences) and **
  user-generated data
  ** (Playlists, PlaylistItems). They can live in the same ObjectBox store — ObjectBox doesn't
  require separate files
  per "table" the way a bundled-vs-writable SQLite split might — but the import script must treat
  them differently (
  Scripture data is pre-seeded and never mutated by the user; playlist data is created/mutated
  entirely on-device).
- Use ObjectBox **relations** (`ToOne`/`ToMany`) for CrossReferences and PlaylistItems rather than
  manually managed
  foreign-key integers — this is exactly the use case ObjectBox relations are good at, and keeps
  query code simple.
- Use ObjectBox's native `Stream` query watching (`box.query(...).watch(triggerImmediately: true)`)
  to drive reactive
  `ValueNotifier`s in Managers — this replaces the "reactive SQL" role that `drift` would have
  played, with no codegen
  beyond the standard ObjectBox model binding.

### 5.2 Entities

```dart
@Entity()
class Verse {
  @Id()
  int id = 0; // ObjectBox internal ID

  @Index()
  String reference = ''; // e.g. "John 3:16" — canonical display reference

  @Index()
  int book = 0; // enum-backed book number (1-66), indexed for range queries
  int chapter = 0;
  int verseNumber = 0;

  String text = ''; // WEB translation text
  String translation = 'WEB'; // fixed for MVP, present for future multi-translation support

  final crossReferences = ToMany<CrossReference>();
}

@Entity()
class CrossReference {
  @Id()
  int id = 0;

  final sourceVerse = ToOne<Verse>();
  final relatedVerse = ToOne<Verse>();

  int weight = 0; // TSK relevance ranking, used to pick "best" related verse for injection
}

@Entity()
class MeditationPlaylist {
  @Id()
  int id = 0;

  String name = '';
  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  final items = ToMany<PlaylistItem>(); // ordered via PlaylistItem.sortOrder
}

@Entity()
class PlaylistItem {
  @Id()
  int id = 0;

  final playlist = ToOne<MeditationPlaylist>();
  final verse = ToOne<Verse>();

  int sortOrder = 0; // explicit ordering within the playlist
}
```

**Notes:**

- `CrossReference` is intentionally a first-class entity (not just an embedded list) so TSK data can
  be bulk-imported as
  flat rows during the DB-build step, matching the source dataset's shape.
- `PlaylistItem.sortOrder` is explicit rather than relying on `ToMany` list order, because ObjectBox
  `ToMany` order is
  not guaranteed to be stable/query-independent — never rely on implicit relation ordering for
  anything user-facing.
- No `AudioCache` entity — cached TTS audio files are tracked on the filesystem (`path_provider` app
  documents dir,
  filename = verse ID + voice hash), not in ObjectBox. This keeps the DB purely about Scripture/user
  data, not binary
  blobs.

### 5.3 Bundling a Pre-Built ObjectBox Database

ObjectBox does **not** support directly shipping a pre-populated store file as a Flutter asset in
the same trivial way
SQLite does (asset copy + open) — the store's internal file layout is tied to `Store.directory` and
platform specifics.
The correct MVP approach:

1. **Build-time step (dev machine, run once):** Write a standalone Dart script (
   `tool/build_bible_db.dart`) that opens a
   fresh ObjectBox `Store`, imports the WEB verse dataset and TSK cross-reference dataset, and
   writes the resulting
   `objectbox` data directory to disk.
2. **Package the resulting data directory** (`objectbox/data.mdb` and friends) as a **zipped Flutter
   asset** (
   `assets/bible_db.zip`) bundled with the app.
3. **On first app launch**, `DatabaseService.init()` checks whether the app's ObjectBox store
   directory already exists
   in the app's documents/support directory. If not, it unzips `assets/bible_db.zip` into that
   directory before opening
   the `Store`. All subsequent launches open the existing store directly — this unzip-on-first-run
   only happens once per
   install.
4. User-generated data (Playlists, PlaylistItems) live in the **same store**, added after the
   bundled Scripture data —
   this is safe because ObjectBox IDs are stable and the import script controls ID assignment for
   bundled entities
   deterministically (or simply lets ObjectBox auto-assign, since Playlists reference Verses via
   `ToOne` relations, not hardcoded IDs).
5. This "unzip pre-built store on first run" pattern trades a small first-launch delay (roughly the
   unzip time,
   negligible for the target DB size) for avoiding a slow verse-by-verse runtime import — the trade
   is clearly correct
   for a Bible-sized dataset.

**Action item**: prototype this unzip-on-first-launch flow **early** (Phase 0) — it's the one piece
of ObjectBox usage
in this project that's non-standard, and it should not be discovered as a blocker mid-MVP.

---

## 6. Proposed Directory Structure

Feature-based, per PFA convention — organized by feature, not by technical layer.

```
lib/
  _shared/
    services/
      database_service.dart        # ObjectBox Store lifecycle, first-run unzip
      tts_service.dart              # flutter_tts wrapper + audio file caching
      audio_player_service.dart     # just_audio + audio_service wrapper
      interaction_manager.dart      # toast/snackbar abstraction (see error handling)
    models/
      # ObjectBox entities live here since Verse/CrossReference are cross-feature
      verse.dart
      cross_reference.dart
      objectbox.g.dart              # generated — do not hand-edit
  features/
    scripture/
      model/
        # (Verse/CrossReference used directly; no extra DTOs needed for MVP)
      manager/
        scripture_manager.dart      # search/browse verses, fetch cross-refs
      pages/
        verse_browser_page.dart
        verse_search_page.dart
      widgets/
        verse_tile.dart
        verse_detail_sheet.dart

    playlist/
      model/
        meditation_playlist.dart    # ObjectBox entity (see _shared or here — team call)
        playlist_item.dart
      manager/
        playlist_manager.dart       # CRUD + reorder, reactive via ObjectBox Stream query
      pages/
        playlist_list_page.dart
        playlist_detail_page.dart
      widgets/
        playlist_item_tile.dart
        add_to_playlist_button.dart

    session/
      model/
        session_state.dart          # enum: idle / playing / paused / completed
      manager/
        session_manager.dart        # activeQueue (listen_it), timer, play/pause/stop commands
      services/
        related_verse_injector.dart # picks + inserts related verse into activeQueue
      pages/
        session_player_page.dart
      widgets/
        session_timer_display.dart
        related_verse_panel.dart
        session_controls_bar.dart

    settings/
      manager/
        settings_manager.dart       # dynamic-play toggle, default timer, TTS rate/pitch
      pages/
        settings_page.dart

  locator.dart                      # get_it registrations, base + scopes if needed
  main.dart
  app.dart                          # MaterialApp, routing, InteractionConnector wrapper

tool/
  build_bible_db.dart                # one-time DB-build script (Section 5.3, step 1)

assets/
  bible_db.zip                       # pre-built ObjectBox store, bundled at build time

docs/
  data-sourcing.md                   # WEB + TSK source URLs and license confirmation (Section 2.1)
```

**Rules carried over from PFA (see `flutter-architecture-expert` skill):**

- Organize by feature, not by layer.
- Promote something to `_shared/` only once a second feature needs it.
- No interface classes/abstract Services unless a second implementation is already planned (the one
  deliberate
  exception: `AudioPlayerService`'s TTS engine seam, per Section 2.2).
- Managers are registered as lazy singletons in `locator.dart`; Views never construct them.

---

## 7. Scalability Note — Path to V2 (Riverpod + Clean Architecture)

`flutter_it`/PFA is the right choice for MVP: minimal boilerplate, no required codegen outside
ObjectBox, fast for a
solo dev to hold in their head. It is **not** the recommendation for a team-scale, long-lived
codebase, and that
trade-off should be made consciously, not accidentally.

**If/when this app scales past solo-MVP** (collaborators join, state graph grows past what Managers
comfortably express,
testing rigor increases), the recommended migration target is **Riverpod + a light Clean
Architecture layering**:

- `get_it`'s `di<T>()` resolves at runtime — a missing registration is a runtime crash, not a
  compile error. Riverpod
  providers are statically analyzable.
- Riverpod's `ProviderScope` overrides are more ergonomic for test isolation than get_it scope
  push/pop, and don't risk
  state leaking between tests if teardown is forgotten.
- `autoDispose` providers matter for a media app with lots of per-session transient state (audio
  queues, TTS cache
  lookups) that shouldn't leak across many session start/stop cycles.
- Riverpod pairs cleanly with ObjectBox's `Stream` queries via `StreamProvider`, giving a more
  uniform state-dependency
  model as the app grows more moving parts.

**Target V2 layering:**

```
lib/
  data/           # ObjectBox, TTS, audio — Repository pattern over today's Services
  domain/         # Pure Dart entities + use-case classes, no Flutter imports
  application/    # Riverpod Notifiers — replace today's Managers
  presentation/   # ConsumerWidgets — replace today's WatchingWidgets
```

This is intentionally close enough to the current feature-based structure that migration is a
targeted swap of the
Manager/Command layer for Notifiers/Providers within the same feature folders — **not** a full
rewrite. **Do not**
front-load this ceremony into the MVP; it is a deliberate, later decision.

---

## 8. Risks & Mitigations

| Risk                                                             | Impact                                                                                                                                       | Mitigation                                                                                                                                                                                                                                                                                                                                                               |
|------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **iOS background audio strictness**                              | Session audio silently stops when device locks or app backgrounds, destroying the core value prop                                            | Use `audio_service`'s `AudioServiceConfig` correctly configured for iOS background modes (`audio` background mode in `Info.plist` is mandatory); test on a **real physical iOS device** (not simulator) starting in Phase 3, not saved for polish at the end. Treat "does audio survive lock screen" as a Phase-3 blocking acceptance test, not a Phase-6 nice-to-check. |
| **TTS voice inconsistency across devices/OS versions**           | Verse readback quality varies (robotic voices, wrong pronunciation of proper nouns like "Nebuchadnezzar"), hurting the meditative experience | Ship with sensible default rate/pitch tuned for calm reading; expose rate/pitch as a Settings control (cheap to build, high perceived-quality payoff); document known TTS quality gap as the reason a premium cloud-voice option is the first planned post-MVP upsell (Section 2.2's deliberate `AudioPlayerService` seam).                                              |
| **ObjectBox pre-built DB bundling is non-standard**              | Could become a late-discovered blocker if the unzip-on-first-run approach hits platform-specific snags                                       | Prototype this specific flow in Phase 0 (Section 5.3, action item) before any feature work begins.                                                                                                                                                                                                                                                                       |
| **TTS audio caching grows unbounded on-device**                  | Users with large playlists could accumulate meaningful local storage over time                                                               | Cache is keyed by verse ID + voice hash; only verses actually played are cached (never the whole Bible); consider a simple LRU eviction or cache-size cap as a fast-follow if it becomes an issue — not required for MVP launch.                                                                                                                                         |
| **Copyright missteps on text/cross-reference sourcing**          | Legal/App Store risk, potential takedown                                                                                                     | Section 2.1's action item — written confirmation of PD status and exact source before any DB-building work starts. Non-negotiable gate.                                                                                                                                                                                                                                  |
| **Dynamic verse injection creates a runaway or repetitive loop** | Poor UX if the same related verse gets re-injected repeatedly, or the queue grows unbounded during a long session                            | `RelatedVerseInjector` should track already-injected verse IDs per session and cap total queue growth (e.g., don't inject if queue length exceeds a sane ceiling); this is a Phase 5 implementation detail to nail down, not an open architectural question, but flagged here so it isn't missed.                                                                        |

---

*End of TRD.md — pending review and approval before Epic/Ticket generation begins.*
