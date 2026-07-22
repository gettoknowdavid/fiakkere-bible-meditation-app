# ScriptureFlow — Epics & Ticket Backlog

---

*Derived from TRD v1.0. Organized for a solo dev, sequenced to front-load the two non-negotiable
gates called out in the TRD: copyright sourcing (§2.1) and the ObjectBox pre-built-DB unzip flow (
§5.3). Tickets follow PFA layering (Service → Manager → View) and `flutter_it` conventions
throughout.*

## Epic Index

| Epic | Title                                                | Gate?                   |
|------|------------------------------------------------------|-------------------------|
| E0   | Foundation & Non-Negotiable Gates                    | Blocks all feature work |
| E1   | Data Layer — ObjectBox Models & Bundled DB           | Blocks E2–E5            |
| E2   | Scripture Feature — Browse & Search                  |                         |
| E3   | Playlist Feature — Build a Meditation Set            |                         |
| E4   | Session Feature — Playback, Timer, Dynamic Injection | Core value prop         |
| E5   | Audio Infrastructure — TTS + Background Playback     | Highest technical risk  |
| E6   | Settings                                             |                         |
| E7   | App Shell, Navigation, Error Handling                |                         |
| E8   | QA, Device Testing & Release Prep                    |                         |

---

## EPIC 0 — Foundation & Non-Negotiable Gates

**Goal:** Clear the two blockers the TRD explicitly forbids skipping (§2.1 copyright sourcing, §5.3
ObjectBox bundling prototype) before any feature code is written. Also stands up the skeleton every
other epic depends on.

**Definition of Done:** `docs/data-sourcing.md` exists with confirmed PD status + source URLs; a
throwaway prototype proves unzip-on-first-run works on both platforms; `flutter_it` skeleton
compiles and runs to an empty splash screen.

### Tickets

**T0.1 — Source WEB text dataset and record license confirmation**

- Research reputable open-source repositories distributing the WEB Bible in a structured format (
  JSON/XML/CSV — book/chapter/verse/text).
- Confirm public-domain status in writing.
- Record exact source URL, retrieval date, and license statement in `docs/data-sourcing.md`.
- **Blocking gate per TRD §2.1** — no DB-building work may start until this ticket is closed.

**T0.2 — Source TSK cross-reference dataset and record license confirmation**

- Locate a flat verse-to-verse TSK mapping dataset (source ref, related ref, weight/rank).
- Confirm PD status, record source + license in `docs/data-sourcing.md`.
- **Blocking gate per TRD §2.1.**

**T0.3 — Prototype: ObjectBox pre-built store unzip-on-first-run**

- Standalone throwaway Flutter project (not the real app).
- Build a tiny ObjectBox store with a handful of dummy entities, zip its data directory as an asset.
- On launch: check for existing store dir in app documents → unzip if absent → open store.
- Test on **both** a real Android device/emulator and iOS simulator (physical iOS if available).
- Document any platform-specific gotchas (file paths, permissions, zip format quirks) in
  `docs/objectbox-bundling-notes.md`.
- **Blocking gate per TRD §5.3** — must be proven before Epic 1 begins.

**T0.4 — Repo scaffold: flutter_it skeleton**

- New Flutter project, add `get_it`, `watch_it`, `command_it`, `listen_it`.
- Create `lib/locator.dart`, `lib/main.dart`, `lib/app.dart` per §6 directory structure.
- Empty `SplashScreen` using `allReady()` pattern from the architecture skill.
- CI-friendly: confirm `flutter analyze` and `flutter test` run clean on an empty project.

**T0.5 — Directory structure scaffold**

- Create the full `lib/_shared/`, `lib/features/{scripture,playlist,session,settings}/` tree from
  TRD §6 with empty placeholder files/folders (`model/`, `manager/`, `pages/`, `widgets/`,
  `services/` as applicable per feature).
- Add `tool/` and `assets/` and `docs/` at repo root.

---

## EPIC 1 — Data Layer: ObjectBox Models & Bundled DB

**Goal:** Everything in TRD §5. Entities, relations, the build-time DB script, and the runtime
bundling/unzip flow productionized (not the throwaway prototype from T0.3).

**Depends on:** E0 (T0.1, T0.2, T0.3 must be closed)

**Definition of Done:** `flutter_tts`-free run of the app opens a fully populated ObjectBox store
containing all WEB verses and TSK cross-references on first launch, unzip happens exactly once,
subsequent launches skip it.

### Tickets

**T1.1 — Define ObjectBox entities**

- Implement `Verse`, `CrossReference`, `MeditationPlaylist`, `PlaylistItem` exactly per TRD §5.2, in
  `lib/_shared/models/` (Verse/CrossReference) and feature `model/` folders (playlist entities) per
  the TRD's "team call" note — decide and document the split in a short ADR comment.
- Run ObjectBox codegen (`build_runner` — the one sanctioned exception to the no-codegen NFR).
- Verify `objectbox.g.dart` builds clean.

**T1.2 — `DatabaseService`: Store lifecycle + first-run unzip**

- `lib/_shared/services/database_service.dart`.
- `init()`: check store directory existence in app documents dir (`path_provider`), unzip
  `assets/bible_db.zip` if absent, open `Store`.
- Register as `registerSingletonAsync` in `locator.dart` (async because of the potential unzip
  delay) — this is the correct use of `init()` doing direct work, not a Command, per the
  architecture skill's manager-init guidance (applies equally to a Service's async setup).
- Expose the opened `Store` for other services/managers to build `Box<T>` queries from.

**T1.3 — `tool/build_bible_db.dart`: DB-build script**

- Standalone Dart script (run once, dev machine only — not shipped).
- Parses the sourced WEB dataset → creates `Verse` records.
- Parses the sourced TSK dataset → creates `CrossReference` records with `ToOne` relations wired to
  the correct `Verse` entities (match by canonical reference).
- Writes resulting ObjectBox data directory to disk.
- Idempotent / re-runnable if source data changes.

**T1.4 — Package `assets/bible_db.zip`**

- Zip the built ObjectBox data directory.
- Register as a Flutter asset in `pubspec.yaml`.
- Verify zip size is reasonable vs. TRD §1.2 NFR#3 (bundled DB should be the single largest asset,
  but total app size must stay reasonable) — record final size in `docs/data-sourcing.md`.

**T1.5 — Data-layer sanity test harness**

- A simple debug-only script or widget test that opens the bundled store and asserts: verse count
  matches expected (~31,000), spot-checks a few known verses (e.g., John 3:16 text matches source),
  spot-checks a few known TSK cross-references resolve correctly via `ToOne`.
- This is the regression guard for T1.3/T1.4 — re-run any time the build script or source data
  changes.

---

## EPIC 2 — Scripture Feature: Browse & Search

**Goal:** `ScriptureManager` + browse/search UI, per TRD §3.1/§6.

**Depends on:** E1

### Tickets

**T2.1 — `ScriptureManager`: browse & lookup**

- `lib/features/scripture/manager/scripture_manager.dart`.
- Methods to query verses by book/chapter (range queries using the indexed `book` field), and fetch
  a single verse's `crossReferences`.
- Expose results as `ValueListenable`s the UI can `watch()`.
- No Commands needed for pure read/browse (per architecture skill: Commands are for user-triggered
  async actions — simple synchronous ObjectBox box queries can be direct manager methods) unless
  search becomes async/debounced (see T2.3).

**T2.2 — `VerseBrowserPage` + `VerseTile`**

- `lib/features/scripture/pages/verse_browser_page.dart`,
  `lib/features/scripture/widgets/verse_tile.dart`.
- Book → Chapter → Verse list navigation.
- `WatchingWidget`s scoped tightly (book list, chapter list, verse list as separate small widgets
  per §3.3 point 5's granularity principle).

**T2.3 — `VerseSearchPage`: text search**

- `lib/features/scripture/pages/verse_search_page.dart`.
- Debounced search-as-you-type over verse text (ObjectBox string contains/starts-with query).
- Use a `Command` here since it's user-triggered and benefits from `isRunning` loading state on
  larger result sets.

**T2.4 — `VerseDetailSheet` with cross-reference list**

- `lib/features/scripture/widgets/verse_detail_sheet.dart`.
- Shows full verse text + "Related Verses" list sourced from `CrossReference.weight`-ranked results.
- Entry point for "Add to Playlist" action (calls into `PlaylistManager`, defined in E3 — stub the
  button here, wire in T3.3).

---

## EPIC 3 — Playlist Feature: Build a Meditation Set

**Goal:** `PlaylistManager` CRUD + reorder, reactive via ObjectBox `Stream` query, per TRD §3.3
point 1.

**Depends on:** E1, E2 (for "add to playlist" entry point)

### Tickets

**T3.1 — `PlaylistManager`: reactive CRUD**

- `lib/features/playlist/manager/playlist_manager.dart`.
- Wrap `box.query(...).watch(triggerImmediately: true)` into a
  `ValueNotifier<List<MeditationPlaylist>>` (per TRD §5.1).
- Commands: `createPlaylistCommand`, `deletePlaylistCommand`, `renamePlaylistCommand`.
- `addVerseCommand(playlistId, verseId)` — creates a `PlaylistItem` with correct `sortOrder` (append
  to end).
- `reorderCommand(playlistId, oldIndex, newIndex)` — explicitly rewrites `sortOrder` values; **never
  ** relies on `ToMany` list order per TRD §5.2 note.
- `removeVerseCommand`.

**T3.2 — `PlaylistListPage` + `PlaylistDetailPage`**

- `lib/features/playlist/pages/`.
- List page: all playlists, create/delete/rename.
- Detail page: ordered verse list (drag-to-reorder), per-item remove.

**T3.3 — `AddToPlaylistButton` widget + wiring into Scripture feature**

- `lib/features/playlist/widgets/add_to_playlist_button.dart`.
- Modal/bottom-sheet picker: existing playlists + "new playlist" inline creation.
- Wire into `VerseDetailSheet` (T2.4) and `VerseTile` (long-press or trailing icon).

**T3.4 — `PlaylistItemTile`**

- `lib/features/playlist/widgets/playlist_item_tile.dart`.
- Displays verse reference + snippet, reorder handle, remove action.

---

## EPIC 4 — Session Feature: Playback, Timer, Dynamic Injection

**Goal:** The core reactive session loop from TRD §3.3 — `SessionManager`, `activeQueue` as
`ListNotifier<Verse>`, `RelatedVerseInjector`, timer.

**Depends on:** E1, E3, E5 (audio must exist to actually play — but queue/timer logic can be built
and unit-tested against a stub audio service first; sequence E4 and E5 in parallel if desired)

### Tickets

**T4.1 — `SessionState` model**

- `lib/features/session/model/session_state.dart`.
- Enum: `idle / playing / paused / completed`.

**T4.2 — `SessionManager`: activeQueue + core commands**

- `lib/features/session/manager/session_manager.dart`.
- `activeQueue` as `listen_it` `ListNotifier<Verse>`.
- `currentVerse` derived via `combineLatest` over queue + current index (per TRD §3.3 point 2/
  `listen_it` role in §3.2 table).
- Commands: `startCommand(playlistId)` (copies playlist → `activeQueue`), `pauseCommand`,
  `resumeCommand`, `stopCommand`, `skipNextCommand`.
- Session state (`idle/playing/paused/completed`) exposed as `ValueListenable<SessionState>`.

**T4.3 — Timer logic**

- Countdown or count-up timer tied to session settings (default length from `SettingsManager`, built
  in E6 — stub a default constant if E6 isn't done yet).
- Timer tick drives session auto-stop at configured duration; does **not** drive full-page
  rebuilds (isolated to `SessionTimerDisplay`, per TRD §3.3 point 5).

**T4.4 — `RelatedVerseInjector` service**

- `lib/features/session/services/related_verse_injector.dart`.
- On verse-completion event, if "Dynamic Play" is enabled (from `SettingsManager`), queries
  `ScriptureManager`/ObjectBox for the highest-weight unused cross-reference and inserts into
  `activeQueue`.
- **Must implement the loop-guard from TRD §8 risk table**: track already-injected verse IDs per
  session (a `Set<int>` scoped to the session instance) and cap total queue growth at a sane
  ceiling (e.g., don't inject past N total queued verses). This is called out as a Phase-5 item in
  the TRD but is architecturally part of this ticket, not deferrable once dynamic play ships.
- No manual wiring elsewhere required — downstream (audio mirroring) reacts to `activeQueue`
  automatically, per the TRD's explicit design intent.

**T4.5 — `SessionPlayerPage`**

- `lib/features/session/pages/session_player_page.dart`.
- Composes `SessionControlsBar`, `SessionTimerDisplay`, `RelatedVersePanel` as separate small
  `WatchingWidget`s.

**T4.6 — `SessionControlsBar` widget**

- Play/pause/stop/skip controls bound to `SessionManager` commands; disabled states driven by
  `command.isRunning` / `SessionState`.

**T4.7 — `SessionTimerDisplay` widget**

- Isolated `WatchingWidget` watching only the timer tick `ValueListenable` — verifies the "
  once-per-second tick doesn't rebuild the whole page" NFR from TRD §3.3 point 5. Worth a quick
  rebuild-count sanity check during dev (e.g., a debug print or `flutter inspector` check) since
  this is an explicit performance claim in the TRD, not just a nice-to-have.

**T4.8 — `RelatedVersePanel` widget**

- Shows the currently-injected related verse (if any) alongside the current verse; isolated
  `WatchingWidget`.

---

## EPIC 5 — Audio Infrastructure: TTS + Background Playback

**Goal:** TRD §2.2 and the #1 risk in §8 — this is the epic most likely to blow the schedule if
under-scoped, so it gets its own explicit sequencing.

**Depends on:** E1 (verse text needed to synthesize)

### Tickets

**T5.1 — `TtsService`: synthesis + file caching**

- `lib/_shared/services/tts_service.dart`.
- Wraps `flutter_tts`.
- `synthesizeAndCache(Verse verse, VoiceSettings settings) → File`: checks `path_provider` app
  documents dir for an existing cached file keyed by `verseId + voiceHash`; if absent, synthesizes
  and writes to disk; returns the file path either way.
- Exposes default rate/pitch tuned for calm reading (TRD §8 mitigation) as constructor/config
  defaults, overridable via `SettingsManager`.

**T5.2 — `AudioPlayerService`: interface + just_audio implementation**

- `lib/_shared/services/audio_player_service.dart`.
- **This is the TRD's one deliberate interface exception** (§2.2, §6 rule) — define
  `AudioPlayerService` as an abstract class/interface *now*, with `JustAudioPlayerService` as the
  concrete MVP implementation, specifically to leave the seam for a future cloud-TTS provider swap.
  Do not add abstractions anywhere else in the codebase without this same justification.
- Wraps `just_audio`'s `ConcatenatingAudioSource`.
- Subscribes to `SessionManager.activeQueue` via `listen_it`'s `listen()` (not `addListener`, per
  architecture skill) and mirrors additions/removals into the `ConcatenatingAudioSource`, calling
  `TtsService.synthesizeAndCache` per verse as needed.

**T5.3 — `audio_service` integration: background/lock-screen playback**

- Configure `audio_service` with `AudioServiceConfig` for iOS background audio mode.
- `Info.plist`: add `audio` to `UIBackgroundModes`.
- Android: verify foreground service notification behaves correctly during an active session.
- Wire lock-screen/notification transport controls (play/pause/skip) back to `SessionManager`
  commands.

**T5.4 — Phase-3 blocking acceptance test: real-device lock-screen survival**

- **Per TRD §8, this must be tested on a real physical iOS device, not simulator, and treated as
  blocking — not deferred to polish.**
- Manual test protocol: start a session, lock the device, wait through at least one full verse
  transition + one TSK injection, confirm audio continues and lock-screen controls work.
- Repeat on a physical Android device.
- Record pass/fail and any OS-version-specific findings in `docs/audio-testing-notes.md`.

**T5.5 — TTS quality/voice settings**

- Expose rate/pitch/voice selection as a `VoiceSettings` value type, persisted via
  `SettingsManager` (E6).
- No work needed here to fix inherent TTS robotic-voice quality (explicitly out of scope per TRD
  §8 — documented as the seam for a future premium voice upsell) — this ticket is just the exposed
  knobs, not a quality fix.

**T5.6 — TTS cache inspection helper (dev-only)**

- Small debug utility to inspect/clear the on-disk TTS cache directory during development. Not a
  shipped feature — LRU eviction is explicitly deferred per TRD §8, but a manual "clear cache" dev
  tool avoids disk bloat during your own testing cycles.

---

## EPIC 6 — Settings

**Goal:** `SettingsManager` — dynamic-play toggle, default timer length, TTS rate/pitch, backed by
`shared_preferences`.

**Depends on:** E0 (can be built early/in parallel with E2–E5 since it has no ObjectBox dependency)

### Tickets

**T6.1 — `SettingsManager`**

- `lib/features/settings/manager/settings_manager.dart`.
- Wraps `shared_preferences`.
- Exposes `ValueNotifier`s: `dynamicPlayEnabled`, `defaultTimerMinutes`, `ttsRate`, `ttsPitch`,
  `ttsVoice`.
- Simple setters that persist immediately (no Command needed for simple synchronous key-value
  writes, consistent with the architecture skill's guidance that Commands are for meaningfully
  async/user-facing operations).

**T6.2 — `SettingsPage`**

- `lib/features/settings/pages/settings_page.dart`.
- Toggle for dynamic play, timer length picker, TTS rate/pitch/voice sliders.

---

## EPIC 7 — App Shell, Navigation, Error Handling

**Goal:** Tie every feature together: routing, `InteractionManager`/global error handling per the
architecture skill, splash/`allReady()` flow.

**Depends on:** E0 (skeleton), informs/wraps all other epics

### Tickets

**T7.1 — `InteractionManager` + `InteractionConnector`**

- `lib/_shared/services/interaction_manager.dart` per architecture skill pattern.
- Sync singleton registered before async services; `InteractionConnector` wraps `MaterialApp`
  content to supply `BuildContext`.

**T7.2 — Global command error handler**

- `Command.globalExceptionHandler` assigned in `main()`, routes to `InteractionManager.showToast`.
- Local `.errors.listen()` overrides added to specific Manager `init()` methods where a friendlier
  message is warranted (e.g., session start failure, TTS synthesis failure) — per architecture
  skill's local-vs-global error flow.

**T7.3 — App routing**

- Simple named-route or declarative router covering: Splash → Verse Browser (home) → Verse Search,
  Playlist List → Playlist Detail, Session Player, Settings.
- Given no auth/accounts (TRD non-goal), routing is flat — no auth-gated route guards needed.

**T7.4 — `SplashScreen` + `allReady()` wiring**

- Final integration of `allReady()` pattern waiting on `DatabaseService` (async singleton from T1.2)
  before navigating to home.
- Confirm cold-start timing meets TRD §1.2 NFR#6 (~1–2s) on a real device — if the first-run unzip
  pushes this over budget, surface an explicit "Setting up your Bible…" progress state rather than a
  blank splash (note: first-run only, subsequent launches should be fast).

**T7.5 — `locator.dart`: final registration wiring**

- All Services and Managers registered as lazy/async singletons in correct dependency order.
- Confirm no widget anywhere constructs a Service or Manager directly — audit via grep for
  constructor calls outside `locator.dart`.

---

## EPIC 8 — QA, Device Testing & Release Prep

**Goal:** Close out NFRs, verify risk mitigations, prepare for store submission.

**Depends on:** All prior epics

### Tickets

**T8.1 — Full regression pass against TRD NFR table (§1.2)**

- Verify each of the 6 ranked NFRs explicitly: offline behavior (airplane mode test), bundle size
  check, background audio (already covered by T5.4 but re-verify post-integration), no unexpected
  codegen beyond ObjectBox (grep for `build_runner` outputs), cold-start timing.

**T8.2 — Dynamic-play loop-guard verification**

- Dedicated test: run a long session with dynamic play enabled, confirm the injector's
  already-injected tracking and queue-length cap (T4.4) actually prevent runaway/repetitive
  injection — this was flagged as a risk in TRD §8 and deserves its own explicit test, not just
  incidental coverage.

**T8.3 — Cross-device TTS quality spot-check**

- Sample a handful of proper-noun-heavy verses (per TRD §8's "Nebuchadnezzar" example) across a few
  OS versions/devices, document known rough edges for future cloud-TTS upsell justification.

**T8.4 — App size + asset audit**

- Confirm `assets/bible_db.zip` is the dominant asset (per NFR#3) and total app size is reasonable
  for the target stores.

**T8.5 — Store listing prep**

- App Store / Play Store metadata, screenshots from `SessionPlayerPage`/`VerseBrowserPage`, privacy
  disclosures (should be minimal/none given zero network calls, zero accounts).

**T8.6 — Final `docs/` audit**

- Confirm `docs/data-sourcing.md`, `docs/objectbox-bundling-notes.md`, `docs/audio-testing-notes.md`
  are complete and would let a future collaborator (or future-you doing the V2 Riverpod migration
  per §7) understand every non-obvious decision without re-deriving it.

---

# Master Development Workflow

**Sequencing rationale:** the TRD itself names two hard gates (copyright sourcing, ObjectBox
bundling prototype) and one schedule-risk epic (background audio) — the workflow below front-loads
exactly those, then lets everything else follow natural data-layer-up dependency order.

```
Phase 0  (Gate)      E0 — Foundation & Non-Negotiable Gates
                      └─ T0.1, T0.2 (copyright/sourcing — written confirmation required)
                      └─ T0.3 (ObjectBox unzip prototype — must succeed before Phase 1)
                      └─ T0.4, T0.5 (skeleton scaffold)

Phase 1  (Data)       E1 — Data Layer (ObjectBox models, build script, bundling)
                      Blocks everything downstream that touches Verse/CrossReference data.

Phase 2  (Parallel)   E2 — Scripture Browse/Search        ┐
                      E5 — Audio Infra (TTS + background)  ├─ can be built concurrently;
                      E6 — Settings                        ┘  E5.T5.4 (real-device lock-screen
                                                                test) should start as early in
                                                                this phase as audio_service is
                                                                wired — per TRD §8, do not defer
                                                                to polish.

Phase 3  (Compose)    E3 — Playlist (depends on E2 for add-to-playlist entry point)
                      E4 — Session (depends on E3 for queue source, E5 for actual playback)

Phase 4  (Integrate)  E7 — App Shell, Navigation, Error Handling
                      Wires every feature Manager into locator.dart, routing, InteractionManager.

Phase 5  (Harden)     E8 — QA, Device Testing, Release Prep
                      Full NFR regression, dynamic-play loop-guard test, store prep.
```

**Standing rules across every phase (non-negotiable per TRD, apply to every ticket above):**

- No ticket produces code-generated output except ObjectBox's `.g.dart` files.
- Every Service wraps exactly one external boundary; every Manager exposes only `ValueListenable`s +
  `Command`s; Views never call Services directly and never construct Managers/Services outside
  `locator.dart`.
- No new interface/abstract class anywhere except `AudioPlayerService` (T5.2) — the one seam the TRD
  explicitly justifies.
- `PlaylistItem.sortOrder` is always explicit — never rely on `ToMany` order.
- Background-audio survival (T5.4) is a **Phase-3-equivalent blocking test**, not a pre-launch
  nice-to-check — treat any failure here as a stop-ship issue, not a backlog item.
- `docs/data-sourcing.md` must be complete and confirmed **before** T1.3 (`build_bible_db.dart`) is
  written — this is the hardest gate in the whole plan and the easiest one to accidentally skip
  under schedule pressure.