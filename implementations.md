# Implemented Features

This document describes the implementation of the features in the SailorBook project.

## 1. Book Search

**Description:** This feature allows users to search for public-domain books using the Open Library API.

**Implementation Details:**

*   **Entry Point:** `LibraryController.searchBooks(String query)` in `apps/app_flutter/lib/controllers/library_controller.dart`.
*   **Service:** `BookService.searchBooks(String query)` in `apps/app_flutter/lib/services/book_service.dart`.
*   **API:** It uses the Open Library Search API: `https://openlibrary.org/search.json`.
*   **Parsing:** The JSON response is parsed in the `_parseOpenLibraryDoc` method in `BookService` into a `Book` object.
*   **State Management:** The `LibraryController` manages the search results and the searching state.

**Status:** Fully implemented.

## 2. Book Download

**Description:** This feature allows users to download EPUB books from the Internet Archive.

**Implementation Details:**

*   **Entry Point:** `LibraryController.downloadBook(Book book)` in `apps/app_flutter/lib/controllers/library_controller.dart`.
*   **Service:** `BookService.downloadBook(Book book)` in `apps/app_flutter/lib/services/book_service.dart`.
*   **Platform-Specific Implementation:**
    *   **Web:** Uses `simple_web_download.dart` to trigger a browser-native download to bypass CORS. The progress is simulated.
    *   **Native (Mobile/Desktop):** Uses the `http` package for streaming downloads and provides real-time progress updates.
*   **Storage:**
    *   **Web:** Uses `WebStorageService` to save the book manifest.
    *   **Native:** Saves the book and its manifest to the application's documents directory.
*   **Error Handling:** Includes a retry mechanism with alternative download URLs.

**Status:** Fully implemented.

## 3. Library Management

**Description:** This feature manages the user's library of downloaded books.

**Implementation Details:**

*   **State Management:** The `LibraryController` in `apps/app_flutter/lib/controllers/library_controller.dart` manages the list of downloaded books.
*   **Service:** The `BookService` provides methods to get the list of downloaded books (`getDownloadedBooks`) and delete books (`deleteBook`).
*   **Storage:** The list of downloaded books is retrieved by reading the `manifest.json` files from the file system (native) or web storage (web).

**Status:** Fully implemented.

## 4. EPUB Parsing and Manifest Generation

**Description:** This feature parses the downloaded EPUB files, extracts the content, and generates a manifest file.

**Implementation Details:**

*   **Entry Point (FFI):** `build_manifest(String epub_path)` in `crates/pdreader_core/src/epub/mod.rs`.
*   **Parsing:** The `parse_epub` function in `crates/pdreader_core/src/epub/parser.rs` uses the `epub` crate to parse the EPUB file.
*   **Content Extraction:** The `normalize_content` function in `crates/pdreader_core/src/epub/parser.rs` uses the `scraper` crate to extract paragraphs from the HTML content of the EPUB.
*   **Manifest Creation:** The `create_manifest` function in `crates/pdreader_core/src/epub/mod.rs` creates a `Manifest` object containing the book's metadata, chapters, and paragraphs.

**Status:** Partially implemented.
*   The EPUB parsing and manifest generation are functional.
*   The content normalization is a **mock implementation** and needs to be improved to handle various EPUB formats and to strip headers/footers as described in the PRD.

## 5. Text-to-Speech (TTS)

**Description:** This feature generates audio from the book's text using a local TTS engine.

**Implementation Details:**

*   **Entry Point (FFI):** `synthesize(String paragraph, VoiceCfg cfg)` and `prebuffer(Vec<String> paragraphs, VoiceCfg cfg, usize n)` in `crates/pdreader_core/src/tts/mod.rs`.
*   **Engine:** The `TtsEngine` in `crates/pdreader_core/src/tts/engine.rs` is responsible for synthesis.

**Status:** Mock implementation.
*   The `TtsEngine` is a **mock implementation** that generates a sine wave instead of actual speech.
*   The integration with the ONNX Runtime and the Piper voice model is not implemented.
*   The `get_bundled_voices` function returns a hardcoded list of voices.

## 6. Audio Caching

**Description:** This feature caches the generated audio to avoid re-synthesizing it every time.

**Implementation Details:**

*   The `cache_key_for` function in `crates/pdreader_core/src/tts/mod.rs` generates a unique key for caching.

**Status:** Not implemented.
*   The `crates/pdreader_core/src/cache/mod.rs` file is empty.
*   There is no implementation for audio caching.

## 7. Player Controls

**Description:** This feature provides UI controls for playing, pausing, and navigating the audio.

**Implementation Details:**

*   **State Management:** The `PlayerController` in `apps/app_flutter/lib/controllers/player_controller.dart` manages the player's state.
*   **Audio Playback:** It uses the `just_audio` package for audio playback.
*   **FFI Integration:** It depends on the `native.loadManifest` and `native.updateLastPosition` FFI functions to interact with the Rust core.

**Status:** Partially implemented.
*   The UI controls are in place.
*   The integration with the Rust core for loading manifests and saving the playback position is not fully functional due to the incomplete FFI bridge.
*   The player's functionality is blocked by the mock implementation of the TTS engine.
