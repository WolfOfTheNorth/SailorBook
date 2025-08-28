# Product Requirements Document (PRD)

**Product Name (working):** Public‑Domain Reader
**Version:** v0.0.1 (Initial MVP for core functionality)
**Owner:** You
**Prepared for:** Claude Code implementation handoff

---

## 0) Executive Summary

A privacy‑first reading and listening app for public‑domain books. The app downloads books from public sources (e.g., Project Gutenberg / Open Library), parses EPUBs locally, and generates human‑like audio **entirely on‑device** using a bundled/local AI TTS engine (e.g., Piper). No servers. Core experience: **Download → Read → Listen** with a Spotify‑grade UI over time.

**Initial MVP goal (v0.0.1):**

* Fetch book metadata and download EPUB.
* Parse chapters/paragraphs locally.
* Generate audio for the current paragraph with a local TTS engine; prebuffer next paragraphs; play with basic controls.

---

## 1) Goals & Non‑Goals

### 1.1 Goals
1
1. Prove the **local TTS playback loop** is smooth and reliable (≤200 ms average gap between paragraphs after prebuffering).
2. Provide a minimal **Library** view to find and download at least one public‑domain title.
3. Provide **basic Player controls**: play/pause, next/prev paragraph, playback speed, jump back 10s.
4. Persist **listening position** per book; resume on restart; work offline after initial downloads.

### 1.2 Non‑Goals (for v0.0.1)

* No accounts, cloud sync, or server components.
* No full Reader typography controls (fonts/themes) yet.
* No sleep timer, voice marketplace, or export‑to‑audio (these are fast‑follow).
* No iOS/Android release in this cut (desktop MVP first).

---

## 2) Target Users & Jobs‑to‑Be‑Done

1. **Privacy‑minded readers:** offline, no tracking, own their books and audio cache.
2. **Accessibility users:** reliable audio with adjustable speed; resume and basic navigation.
3. **Commuters/students:** quick book discovery, instant play, jump back when missed something.

---

## 3) Scope

### 3.1 In‑Scope (v0.0.1)

* **Flutter‑first** MVP targeting **Android + Desktop (macOS/Windows/Linux)**. iOS targeted in v0.1 once TTS core passes App Store review.
* Integration with public‑domain sources (Open Library for metadata/covers; Project Gutenberg for EPUB downloads).
* Local text pipeline: EPUB → chapter/paragraph extraction → normalization.
* Local TTS pipeline: paragraph → PCM/OGG, **LRU cache** by content hash.
* Basic player and minimal library UI.

### 3.2 Out of Scope (v0.0.1)

* iOS release (we’ll validate ONNX/Piper packaging first in v0.1).
* Enhanced UI polish; karaoke highlighting; typography customization; sleep timer; bookmarks UI; monetization. (Documented as **Fast‑Follow**.)

---

## 4) Product Design Overview

### 4.1 Information Architecture

* **Home (Library)** → list of downloaded books; "+ Add Book" (search/fetch).
* **Book Details** → cover, title, author, size, chapters; **Play**.
* **Player** (compact) → play/pause, prev/next paragraph, speed, “↺ 10s”.

### 4.2 Future UI Modes (for v0.1+ reference)

* **Reading Mode:** full‑text view with font/size/theme; tap‑to‑speak from cursor.
* **Audio Mode (Spotify‑style):** large cover, current sentence bolded, next sentence preview, progress, sleep timer, bookmark button, voice & speed.

> **Design Principle:** clean, minimal, tactile controls; no clutter; “works instantly”.

---

## 5) Monetization (Planned, not in v0.0.1)

* Free core. One‑time **\$9.99 Pro** unlock for: advanced audio controls (sleep timer, pitch/EQ), Reader theming, extra curated local voices, export chapter audio, local backup/restore.

---

## 6) Functional Requirements

### 6.1 Library & Discovery

* **FR‑LIB‑1:** As a user, I can search for a public‑domain title and view details (title, author, cover, source, file size estimate).
* **FR‑LIB‑2:** I can download an EPUB to local storage with visible progress and error states.
* **FR‑LIB‑3:** Downloaded books appear in Library; I can remove a book (and optionally its audio cache).

### 6.2 Parsing & Normalization

* **FR‑PARSE‑1:** The app extracts chapters from EPUB, ignoring front/back matter when possible.
* **FR‑PARSE‑2:** The app segments text into **paragraphs** (and sentences for future highlighting), normalizing whitespace, stripping headers/footers/footnotes heuristically.
* **FR‑PARSE‑3:** The app stores a per‑book **manifest.json** with chapter/paragraph indices and word counts.

### 6.3 Local TTS & Caching

* **FR‑TTS‑1:** Given a paragraph and voice settings, generate audio locally via Piper/ONNX.
* **FR‑TTS‑2:** Cache audio as `.ogg` (or `.wav`) using key = `hash(text + voiceId + rate + pitch)`.
* **FR‑TTS‑3:** Maintain a **per‑book LRU cache** with user‑configurable cap (default 1–3 GB).
* **FR‑TTS‑4:** Prebuffer the **next N paragraphs** (default 2–3) while playing the current one.

### 6.4 Playback

* **FR‑PLAY‑1:** Play/pause; next/prev paragraph; **jump back 10s** within paragraph.
* **FR‑PLAY‑2:** Adjustable **speed** (0.8×–2.5×). (Pitch optional later.)
* **FR‑PLAY‑3:** Resume playback position per book on app relaunch.
* **FR‑PLAY‑4:** Handle end‑of‑paragraph → next paragraph with average gap **≤200 ms** (after prebuffer).

### 6.5 Settings & Info

* **FR‑SET‑1:** Voice selection screen with at least one bundled English voice; show license/attribution for each voice/model.
* **FR‑SET‑2:** Storage management (clear cache per book / all).
* **FR‑SET‑3:** About/Attribution & Public‑Domain guidance; jurisdiction note.

---

## 7) Non‑Functional Requirements (NFRs)

* **NFR‑Perf‑1:** TTS synthesis sustained at **≥1.2× realtime** on a typical laptop at default quality.
* **NFR‑Perf‑2:** Paragraph boundary gap **≤200 ms avg** with prebuffering.
* **NFR‑Reliability‑1:** Survive app kill/OS sleep without data loss; resume last known position.
* **NFR‑Privacy‑1:** No network calls needed during playback (post model/book download).
* **NFR‑Portability‑1:** Core TTS and parsing implemented in Rust to enable future Flutter/React Native bindings via FFI.

---

## 8) Platforms & Tech Choices

### 8.1 MVP Platform — **Flutter First**

* **Flutter** for UI + navigation + state management across Android and Desktop (macOS/Windows/Linux).
* **Rust TTS + parsing core** compiled as a native library and bridged via **`flutter_rust_bridge`** (or plain FFI). This keeps the heavy lifting in highly portable Rust while Flutter owns the experience layer.

### 8.2 Packages (Flutter)

* Navigation: **`go_router`**
* State: **`riverpod`** (or `flutter_riverpod`)
* Audio playback: **`just_audio`**, **`audio_session`** (background audio later via `audio_service`)
* Storage/paths: **`path_provider`**, **`shared_preferences`** (or a small JSON store), optional `isar`/`drift` later
* HTTP/OPDS: **`http`**, optional `dio`
* EPUB parsing (Dart side for light metadata only): `epubx` (Rust will do the robust extraction)
* Theming/Fonts: **Material 3** + Google Fonts (`inter`, `lora`)

### 8.3 Core Engine (Reusable)

* **Rust** crate exposes:

  * `synthesize(paragraph: &str, VoiceCfg) -> OggBytes`
  * `prebuffer(queue: Vec<ParagraphRef>) -> Vec<OggBytes>`
  * `hash_key(paragraph, voiceId, rate, pitch) -> String`
  * EPUB → manifest building: `build_manifest(epub_path) -> Manifest`
* **ONNX Runtime** linked for Android/iOS/desktop. If iOS packaging becomes a blocker, provide a **toggle fallback** to device TTS on iOS in v0.1 while keeping Piper on Android/Desktop.

---

## 9) Integrations & Data Sources

* **Open Library** for search/metadata/covers (HTTP API).
* **Project Gutenberg** for EPUB downloads (OPDS feed or direct link).
* Respect robots/ToU; polite request rate. Avoid branding misuse.

---

## 10) Data Model & Storage

```
/books/
  {bookId}/
    book.epub
    manifest.json        // chapters[], paragraphs[], sentenceOffsets[] (optional), wordCounts
    audio-cache/
      {hash}.ogg         // hash(text+voice+rate+pitch)

/settings/
  app.json               // voiceId, rate, cacheCapGB, lastOpenedBookId

/library.json            // downloaded books metadata & lastPosition
```

**Manifest (per book):**

```json
{
  "bookId": "ol-1234",
  "title": "Moby-Dick",
  "chapters": [ { "id": 1, "title": "Loomings", "paragraphs": [0,1,2] } ],
  "paragraphs": [
    { "id": 0, "chapterId": 1, "text": "Call me Ishmael.", "wordCount": 3 },
    { "id": 1, "chapterId": 1, "text": "Some years ago..." }
  ],
  "lastPosition": { "chapterId": 1, "paragraphId": 12, "offsetMs": 0 }
}
```

---

## 11) User Stories with Acceptance Criteria (for Claude Code)

### Story S1 — Search & Download

**As a** user **I want** to find and download a public‑domain book **so that** I can listen offline.

* **AC1:** Search yields results with title/author/cover.
* **AC2:** Tapping a result shows details and a **Download** button.
* **AC3:** Download progress visible; failure shows retry.
* **AC4:** On success, book appears in Library with size and status.

### Story S2 — Parse to Paragraphs

**As a** system **I want** to extract chapters/paragraphs from EPUB **so that** audio generation works per paragraph.

* **AC1:** Manifest contains ordered chapters and paragraphs.
* **AC2:** Normalization removes repeated headers/footers; keeps punctuation.
* **AC3:** Edge‑case EPUBs still produce paragraphs (fallback to block/length heuristics).

### Story S3 — Local TTS Synthesis & Cache

**As a** listener **I want** local audio generation **so that** playback works offline.

* **AC1:** Current paragraph can be synthesized and played.
* **AC2:** Next 2–3 paragraphs are prebuffered during playback.
* **AC3:** Cache stores audio by hash; replays are instant if present.
* **AC4:** Changing speed/voice invalidates cache key and regenerates.

### Story S4 — Playback Controls

**As a** listener **I want** basic controls **so that** I can navigate easily.

* **AC1:** Play/pause; next/prev paragraph works.
* **AC2:** Jump back 10s within paragraph (seek within current audio).
* **AC3:** Speed control 0.8×–2.5× affects playback without pitch artifacts (acceptable quality).
* **AC4:** On app relaunch, playback resumes at last position.

### Story S5 — Settings & Storage

**As a** user **I want** to manage storage and voice **so that** I control space and sound.

* **AC1:** Choose at least one bundled voice; see attribution.
* **AC2:** Clear cache per book / all; show space usage.
* **AC3:** App works offline after downloads.

---

## 12) UX Notes (for future v0.1)

* **Reading Mode:** adjustable font/size/line‑height; dark/light/sepia; per‑book reading profile; "Speak from here" button.
* **Audio Mode:** large cover; bold current sentence; smaller next sentence; progress bar; sleep timer; bookmark; voice & speed chip.
* **Design language:** clean cards, generous spacing, rounded corners, subtle shadows; avoid skeuomorphism.

## 12A) Wireframes (ASCII)

### Home / Library

```
┌──────────────────────────────────────────────┐
│  Public‑Domain Reader                       │
│  [ Search ………………… ]   (+ Add Book)          │
├──────────────────────────────────────────────┤
│  ▢ Moby‑Dick         ▢ Dracula             │
│  by Melville         by Stoker             │
│  [▶ Play] [Details]  [▶ Play] [Details]    │
│                                              │
│  ▢ Frankenstein      ▢ Pride & Prejudice    │
│  by Shelley          by Austen              │
│  [▶ Play] [Details]  [▶ Play] [Details]    │
└──────────────────────────────────────────────┘
```

### Book Details

```
┌──────────────────────────────┐
│ ◀ Back   Moby‑Dick           │
├──────────────────────────────┤
│ [Cover]  Title, Author       │
│ [Download / Open]            │
│ Chapters:                    │
│  1. Loomings   [Play]        │
│  2. The Carpet‑Bag [Play]    │
└──────────────────────────────┘
```

### Reading Mode (within a book)

```
┌──────────────────────────────────────────────┐
│ ◀ Back   Moby‑Dick           [⋯]            │
├──────────────────────────────────────────────┤
│  [Aa−]  [Aa+]  [Font ▼]  [Theme ○●]  [▶]    │
├──────────────────────────────────────────────┤
│  Call me Ishmael. Some years ago…            │
│  …                                           │
│                                              │
│  (pagination / scroll)                       │
└──────────────────────────────────────────────┘
```

### Audio Mode (Spotify‑style)

```
┌──────────────────────────────────────────────┐
│ ◀ Back        Moby‑Dick        [Voice ▼]    │
├──────────────────────────────────────────────┤
│                  [Cover Art]                 │
│                                              │
│  **Call me Ishmael.**                        │
│  Next: Some years ago, never mind how long.  │
│                                              │
│  ────────●──────────────  02:14  05:18       │
│  [↺10s]  [⏯]  [⏭]   Speed 1.5×  [Sleep ⏰]   │
└──────────────────────────────────────────────┘
```

## 12B) UI Style Guide (shadcn‑inspired for Flutter)

**Design Language:** Minimal, modern, high contrast, generous whitespace. We emulate **shadcn/ui** tokens in Flutter via a custom **Material 3 theme**.

### Design Tokens

* **Radius:** `xs: 6`, `sm: 10`, `md: 14`, `lg: 20`, `xl: 28` (use `lg`/`xl` for cards/dialogs)
* **Spacing (dp):** 4, 8, 12, 16, 20, 24, 32
* **Elevation:** 0, 1, 3, 6 (soft shadows on cards/buttons)
* **Typography:**

  * Display: Inter/Lora (DisplayLarge 32/36, Medium 24/28)
  * Body: Inter (BodyLarge 16/24, BodyMedium 14/20)
  * Mono (for debug): JetBrains Mono 12/18
* **Color (Light):**

  * `bg`: #0B1015 (use **inverted for Dark**),
  * `surface`: #0F172A (slate‑900)
  * `card`: #111827 (slate‑800)
  * `primary`: #4F46E5 (indigo‑600)
  * `accent`: #10B981 (emerald‑500)
  * `text`: #E5E7EB (slate‑200)
  * `muted`: #94A3B8 (slate‑400)
* **Color (Dark):** invert surfaces; keep `primary/accent` consistent; ensure WCAG AA.

### Components

* **Top App Bar:** flat, 56dp, title center, actions right.
* **Card:** radius `lg`, elevation 3, internal padding 16–20.
* **Button (Primary):** filled, radius `md`, height 44, icon‑leading spacing 8.
* **Chip:** for speed/voice; compact 32–36dp height.
* **Slider:** for progress; thumb 12dp; track height 4dp.

### Motion

* Easing: standard Material; durations 120–240ms.
* Screen transitions: fade‑through or shared‑axis.

### Accessibility

* Text scaling up to 150%; color contrast AA; focus indicators on all interactive widgets; large tap targets (≥44dp).

### Sample Theme Snippet (pseudocode)

```dart
final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: indigo),
  textTheme: GoogleFonts.interTextTheme(),
  cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: 20.r)),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle(
    shape: RoundedRectangleBorder(borderRadius: 14.r),
    minimumSize: Size(44.h, 44.h),
  )),
);
```

---

## 13) Technical Spec (Developer‑Facing)

### 13.1 Rust Core (crate: `pdreader_core`)

* **Modules:**

  * `epub`: open, extract spine, HTML → text, chapter boundaries.
  * `normalize`: strip boilerplate; sentence/paragraph segmentation.
  * `tts`: Piper/ONNX Runtime bindings; `synthesize()` returns OGG/PCM.
  * `cache`: keying, LRU, disk IO.
  * `manifest`: read/write per‑book JSON manifest; last position updates.
* **Public API:**

  ```rust
  pub struct VoiceCfg { pub id: String, pub rate: f32, pub pitch: f32 }
  pub fn synthesize(paragraph: &str, cfg: &VoiceCfg) -> Result<Vec<u8>>
  pub fn prebuffer(paragraphs: &[&str], cfg: &VoiceCfg, n: usize) -> Result<Vec<Vec<u8>>>
  pub fn key_for(paragraph: &str, cfg: &VoiceCfg) -> String
  pub fn build_manifest(epub_path: &str) -> Result<Manifest>
  ```

### 13.2 Flutter Shell

* **Layers:**

  * **UI** (Flutter/Material 3): pages, widgets, responsive layouts.
  * **App State** (Riverpod): `LibraryController`, `PlayerController`, `SettingsController`.
  * **Platform Channel/FFI**: calls into Rust functions for parse/tts/cache.
* **Services:**

  * `BookService`: search (Open Library), download (Gutenberg), file IO.
  * `ManifestService`: calls Rust `build_manifest` to generate `manifest.json`.
  * `TtsService`: wraps FFI calls; manages prebuffer queue and LRU cache.
  * `AudioService`: uses `just_audio` to play current paragraph and handle seamless next.
* **Commands/Use‑cases:**

  * `searchBooks(query) -> List<BookMeta>`
  * `downloadBook(bookId) -> DownloadResult`
  * `openBook(bookId) -> Manifest`
  * `playParagraph(bookId, paragraphId, VoiceCfg)`
  * `nextParagraph()` / `prevParagraph()` / `seek(ms)` / `setSpeed(x)`
  * `getLastPosition()` / `setLastPosition()`

### 13.3 Audio

* Feed OGG/PCM bytes from Rust into `just_audio` via in‑memory stream or temp file. Ensure smooth handoff at paragraph boundaries; small cross‑fade (50–100ms) optional.

### 13.4 Threads/Isolates

* Run Rust TTS calls on a background isolate/worker to avoid jank. Prebuffer N paragraphs while one is playing.

### 13.5 Error Handling

* Network errors → user‑visible retry with context.
* EPUB parse failure → fallback segmentation (block/length heuristics).
* TTS failure → retry once; if persistent, prompt to change voice settings.

---

## 14) Performance & QA Plan

* **Benchmarks:**

  * Measure synthesis realtime factor on mid‑range laptop; target ≥1.2×.
  * Measure paragraph gap over 100 transitions; target ≤200 ms avg (≤400 ms p95).
* **Automated tests:**

  * EPUB fixture parse → manifest snapshot test.
  * Cache key stability test.
  * TTS roundtrip (smoke): synthesize known paragraph → bytes present.
* **Manual test script:**

  1. Search and download "Moby‑Dick" (or fixture).
  2. Open and play; verify smooth paragraph transitions.
  3. Change speed to 1.5×; verify re‑synthesis uses new cache keys.
  4. Quit/reopen; verify resume works.

---

## 15) Privacy, Legal, Compliance

* **Offline‑first:** no telemetry by default; developer debug logging only, local.
* **Licensing:** ship only voices compatible with redistribution/commercial use; include attribution screen for voice models and source texts as required by their licenses/ToU.
* **Public Domain Jurisdictions:** later add toggle (US/CA/EU) prefiltering; initial MVP warns users to verify jurisdiction.
* **Branding:** do not imply endorsement by source repositories.

---

## 16) Roadmap (High Level)

* **v0.0.1 (this PRD):** **Flutter** MVP (Android + Desktop). Core loop proven with Rust TTS via FFI.
* **v0.1:** Audio Mode UI with sentence highlighting; Reading Mode (fonts/themes basics); sleep timer; bookmarks UI; storage UI; attribution polish; **iOS enablement** (fallback to system TTS if ONNX packaging blocked).
* **v0.2:** Background audio (`audio_service`), download manager improvements, PD jurisdiction filter, initial monetization plumbing (gated Pro screens).
* **v0.3:** \$9.99 Pro, voice packs, export chapter audio, collections.

---

## 17) Open Questions

1. Which default English voice(s) to bundle for best quality vs size?
2. OGG vs WAV in cache—favor OGG size or WAV simplicity?
3. Target desktop OS versions (Win 10+, macOS 12+?)
4. Future: sentence‑level timings—accept approximation or add alignment step?

---

## 18) Handoff to Claude Code — Developer Checklist

* [x] Create Flutter repo `apps/app_flutter` and Rust crate `crates/pdreader_core`.
* [x] Integrate **`flutter_rust_bridge`** (or FFI) to call Rust from Dart.
* [x] Implement Rust crate modules (`epub`, `normalize`, `tts`, `cache`, `manifest`).
* [ ] Link ONNX Runtime; bundle at least one commercial‑OK voice model.
* [x] Add Flutter packages: `go_router`, `flutter_riverpod`, `just_audio`, `audio_session`, `path_provider`, `http`.
* [x] Implement Library (search/download/list) and Book Details.
* [x] Implement paragraph manifest build via Rust; persist `manifest.json`.
* [x] Implement Player: play/pause, next/prev paragraph, seek back 10s, speed.
* [x] Implement prebuffer queue + LRU cache on disk; resume last position.
* [x] Add basic theming per **UI Style Guide**; wire **Reading/Audio** mode routes (stubs ok for v0.0.1).
* [x] Tests: EPUB parse snapshot; cache key stability; TTS smoke.
* [x] CI: Android + Desktop builds; attach one PD book as fixture for QA.

**Dev Notes for Claude Code:**

* Keep Rust API surface tiny and stable; prefer streaming bytes via temp file for `just_audio` initially.
* Isolate TTS work off the UI thread; limit prebuffer to 2–3 paragraphs.
* Provide a compile‑time flag to disable Piper and use platform TTS (for iOS experiments).
* Use the wireframes as a baseline; defer polish until v0.1.
