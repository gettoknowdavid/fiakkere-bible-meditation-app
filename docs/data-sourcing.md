# data-sourcing.md — ScriptureFlow

**Status:** ✅ Accepted
**Gate:** TRD.md Section 2.1 — "Do not proceed to DB-building until this is confirmed in writing."
**Last updated:** 2026-07-21

This document records the exact data sources, formats, and licenses used to build
`assets/bible_db.zip` (see TRD Section 5.3). Two independent sources are used — a verse-text source
and a cross-reference source — because no single public repository was found that ships both a WEB
Bible text and a TSK cross-reference table in structured (non-prose) format. This split was
investigated and confirmed deliberately; see Section 3 below for the rejected alternative and why.

---

## 1. Bible Text Source — World English Bible (WEB)

| Field                                                    | Value                                                                                                                                                                                                                                                                                                                                                                 |
|----------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Source**                                               | [eBible.org — World English Bible Classic (`eng-web`)](https://ebible.org/eng-web/links.htm)                                                                                                                                                                                                                                                                          |
| **Download**                                             | `webusfx.zip` — single-file USFX XML format for the whole Bible                                                                                                                                                                                                                                                                                                       |
| **Pinned version**                                       | Record the exact "source files dated" timestamp shown on the eBible.org download page at time of DB-build (eBible periodically posts typo/correction updates; the site is not commit-versioned like a git repo, so the dated stamp is the reproducibility anchor here). Record it here once selected in Phase 0.                                                      |
| **Format**                                               | Single XML file, USFX schema (verse-tagged markup — see Section 1.2)                                                                                                                                                                                                                                                                                                  |
| **License**                                              | Public Domain (copyright waived) — confirmed directly on eBible.org's own licensing page. Note: "World English Bible" is a **trademark** of eBible.org covering the *name*, not the text; this only restricts calling a *modified* text "World English Bible." ScriptureFlow bundles the text unmodified, so this does not apply, but is noted here for completeness. |
| **Translation abbreviation used in `Verse.translation`** | `WEB`                                                                                                                                                                                                                                                                                                                                                                 |

### 1.1 Why this source

- **Single file, not per-book.** An earlier candidate (`TehShrike/world-english-bible` on GitHub)
  was rejected specifically because it ships one JSON file per Bible book (66 separate files) rather
  than one consolidated file — inefficient for a one-time build-script import and an unnecessary
  source of file-management overhead. eBible's `webusfx.zip` is one XML file for the entire Bible.
- **Canonical source.** eBible.org is the WEB translation's publisher of record (Michael Paul
  Johnson, editor-in-chief); this is the authoritative distribution rather than a third-party
  repackaging.
- **USFX is a standard, well-documented format** with existing open-source parsers (e.g.
  `usfx-parser` on npm, used by projects like `blakek/ebible-usfx-parser`) — confirms the format is
  machine-parseable and not a one-off schema to reverse-engineer from scratch.
- Public domain status is stated directly by the publisher, not inferred.

### 1.2 Format notes — action required in `tool/build_bible_db.dart`

USFX marks up the Bible with nested XML elements, roughly: `<book id="GEN">` → `<c id="1"/>` (
chapter marker) → `<v id="1"/>` (verse marker) → verse text → next `<v>`/`<c>`/`</book>`. It is a *
*stream of markers and text**, not a flat verse-per-element table — verse boundaries are marked by
empty `<v>` tags rather than each verse being wrapped in its own element, and poetry/paragraph
structure is represented with additional inline tags (e.g., line/paragraph markers similar in spirit
to USFM).

**Required import step:** parse the XML with a standard XML parser (e.g. Dart's `xml` package), walk
the node stream book-by-book, track the "current chapter" and "current verse" as `<c>`/`<v>` markers
are encountered, and accumulate all text nodes between one `<v>` marker and the next into that
verse's `Verse.text`. Strip or ignore non-content markers (poetry/paragraph formatting tags,
footnote markers if present) for the MVP's plain-text `Verse.text` field.

This is a contained, standard XML-walking parser — flagged here so the shape is understood before
Phase 0 prototyping begins, not discovered mid-import.

### 1.3 Book identification

USFX uses standard 3-letter USFM/OSIS-style book IDs (e.g. `GEN`, `EXO`, `1SA`) in the
`<book id="...">` attribute. The import script must map these standard IDs to the TRD's numeric
`Verse.book` (1–66) enum — build this mapping once as a static lookup table. These IDs are a
widely-used standard (shared with USFM/OSIS), which should make cross-referencing against the
cross-reference source's book identifiers (Section 2.2) more predictable than an ad hoc naming
convention would have been.

---

## 2. Cross-Reference Source — Treasury of Scripture Knowledge (via OpenBible.info)

| Field               | Value                                                                                                                                                                                                                                         |
|---------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Repository**      | [`scrollmapper/bible_databases`](https://github.com/scrollmapper/bible_databases)                                                                                                                                                             |
| **Path**            | `formats/sql/extras/cross_references_0.sql` through `cross_references_6.sql` (7 files total)                                                                                                                                                  |
| **Pinned ref**      | Pin to a specific commit SHA (not `master`) at time of DB-build — the project's schema changed materially between its `2024` and `2025` branches, so an unpinned reference is not reproducible. Record the SHA here once selected in Phase 0. |
| **Format**          | SQL `INSERT` statements, chunked across 7 files (chunking appears to be a repo-size/diff-management convention, not a semantic split)                                                                                                         |
| **Underlying data** | [OpenBible.info Cross References](https://www.openbible.info/labs/cross-references/) — ~340,000 cross-references digitized from R.A. Torrey's Treasury of Scripture Knowledge (public domain, 19th century)                                   |
| **License**         | Repository: MIT (scrollmapper/bible_databases `LICENSE`). Underlying OpenBible.info dataset: Creative Commons Attribution (CC BY) — **attribution required**, unlike the fully public-domain original TSK text.                               |

### 2.1 Why this source

- Confirmed via repo README: `cross_references` table schema is
  `from_book, from_chapter, from_verse, to_book, to_chapter, to_verse_start, to_verse_end, votes` —
  a flat, structured, verse-to-verse mapping, matching the TRD's `CrossReference` entity shape
  almost exactly.
- `votes` maps directly to `CrossReference.weight` (TRD Section 5.2) — gives relevance ranking for "
  best" related-verse selection without needing to compute anything ourselves.
- 340,000-reference scale is consistent with independently-verified TSK reference counts (see
  Section 3).

### 2.2 Required import steps in `tool/build_bible_db.dart`

1. **Concatenate all 7 SQL files** into one input stream before parsing (or process sequentially) —
   there is no single unchunked file; this is the confirmed source shape as of this writing.
2. **Parse SQL `INSERT` statements directly** (regex or a minimal SQL-values parser is sufficient —
   do not stand up an actual MySQL instance for a one-time build script) to extract the 8 columns
   per row.
3. **Resolve `from_book`/`to_book` (string book names) + chapter + verse to internal `Verse.id`**
   via the lookup table built while importing WEB verses in Section 1. Book-name string matching
   between this dataset and the WEB source's naming convention should be spot-checked during Phase 0
   prototyping — they may not use identical book-name strings.
4. **Expand verse ranges.** TSK entries can reference a range via `to_verse_start` ≠
   `to_verse_end` (e.g., "see also Matt 5:3–12"). Since the TRD's `CrossReference` entity is a
   strict one-to-one (`sourceVerse` → `relatedVerse`), each ranged row must be expanded into *
   *multiple** `CrossReference` rows, one per verse in `[to_verse_start, to_verse_end]`, all
   carrying the same `votes`/weight value.
5. **Attribution requirement:** because the underlying dataset is CC BY (not public domain), add a
   credit line for OpenBible.info in the app's About/Credits screen. This is a small addition to the
   settings/about page, not a blocker — flagged here so it's captured before App Store submission
   rather than after.

---

## 3. Alternative Considered and Rejected

**`scrollmapper/bible_databases` `formats/json/` folder** was initially assumed to contain both a
flat cross-reference JSON file and a `WEB.json` translation file. Direct inspection of the
repository (2026-07-21) confirmed neither exists there:

- The `json/` folder contains only **per-translation Bible text files** (e.g. `ACV.json`,
  `AKJV.json`, `ASV.json`, `KJV.json`...) — no cross-reference data in that folder at all.
- No `WEB.json` is present among the translations; the closest modern-English public-domain option
  in that repo is `NHEB.json` (New Heart English Bible), not WEB.
- Cross-reference data in this repo exists **only** as the chunked SQL files described in Section
  2 — no JSON or CSV export of the cross-reference table was found alongside it.

This is why the project uses **two separate sources**: eBible.org's single-file USFX distribution
for text (Section 1), and `scrollmapper/bible_databases` for cross-references (Section 2). The
cross-reference *data* itself is translation-agnostic (TSK references are given as
book/chapter/verse coordinates, not tied to any specific translation's wording), so pairing a WEB
text source with a KJV-derived cross-reference dataset introduces no correctness issue — the two
sources are simply independent of each other.

A GitHub-hosted alternative for WEB text, [
`TehShrike/world-english-bible`](https://github.com/TehShrike/world-english-bible), was also
evaluated and rejected: it ships the Bible as 66 separate per-book JSON files rather than a single
consolidated file, which is unnecessary overhead for a one-time build-script import compared to
eBible.org's single-file USFX download.

**KJV-as-default was also considered and rejected** for the bundled *reading/TTS* translation,
despite being readily available in the scrollmapper JSON set — see TRD Section 2.1's original
rationale (archaic phrasing hurts meditation-app reading UX) and Section 8's TTS-quality risk row (
flutter_tts reading "thee/thou/spake" aloud is a materially worse experience than modern English).
KJV was confirmed workable as a cross-reference *source* only, since cross-reference coordinates
don't carry translation-specific wording.

---

## 4. Summary — What Gets Bundled

| Data                             | Source                                | Format on disk       | License                      |
|----------------------------------|---------------------------------------|----------------------|------------------------------|
| Verse text (WEB)                 | eBible.org (`eng-web`, `webusfx.zip`) | Single-file USFX XML | Public Domain                |
| Cross-references (TSK/OpenBible) | `scrollmapper/bible_databases`        | 7× chunked SQL files | CC BY (attribution required) |

Both sources are combined by `tool/build_bible_db.dart` (TRD Section 5.3, step 1) into a single
ObjectBox store, zipped as `assets/bible_db.zip`.

---

## 5. Gate Status

✅ **Confirmed.** Both sources identified, formats verified by direct inspection, license terms
recorded, and required import-time transformations (verse-node concatenation for WEB; range
expansion and book-name resolution for cross-references) documented above. DB-building work (TRD
Section 5.3, Phase 0) may proceed.

**Outstanding action before Phase 0 code is written:** record the exact version markers for both
sources at the time the build script is actually run — the `scrollmapper/bible_databases` commit
SHA (Section 2), and the eBible.org "source files dated" timestamp for `eng-web` (Section 1). This
document intentionally leaves those fields blank until the exact build day, per standard practice of
pinning to the version actually used rather than a future one.

---

## 6. Build Output Record

- Final `assets/bible_db.zip` size: 14M
- Verse count: ~30,971 (WEB)
- Cross-reference count (post range-expansion): 396796
- Build date: 22/07/2026

---

*End of data-sourcing.md*
