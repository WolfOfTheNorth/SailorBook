# Changelog

All notable changes to the Public-Domain Reader project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Reading mode with adjustable fonts and themes
- Sentence-level highlighting during audio playback
- Sleep timer functionality
- iOS platform support
- Background audio playback
- Enhanced download manager
- Public domain jurisdiction filtering
- Additional voice models
- Bookmarks and notes system

## [0.0.1] - 2024-01-01

### Added
- Initial MVP implementation
- Flutter-based cross-platform UI (Android, Desktop, Web)
- Rust core library with FFI bridge
- EPUB parsing and text normalization
- Mock TTS implementation (Piper/ONNX integration planned)
- Audio caching with LRU eviction
- Basic audio player with controls:
  - Play/pause/stop
  - Next/previous paragraph
  - Speed adjustment (0.8x - 2.5x)
  - Seek back 10 seconds
- Library management:
  - Search public domain books (Open Library API)
  - Download EPUB files
  - View book details and chapters
- Local storage and offline functionality
- Playback position persistence
- Material 3 theming with dark/light mode
- Comprehensive test suite:
  - Unit tests for Rust and Flutter
  - E2E tests with Playwright
  - CI/CD pipeline with GitHub Actions
- Privacy-first architecture (no servers, no tracking)
- Voice configuration (rate, pitch, voice selection)
- Settings page with attribution and privacy info

### Technical Implementation
- **Frontend**: Flutter 3.16+ with Riverpod state management
- **Backend**: Rust core library with EPUB, TTS, caching, and manifest modules
- **Bridge**: flutter_rust_bridge for FFI communication
- **Audio**: just_audio for playback
- **Storage**: Local file system with JSON manifests
- **Testing**: Playwright for E2E testing
- **CI/CD**: GitHub Actions with multi-platform builds

### Architecture
```
Flutter UI (Material 3) 
    ↕ FFI Bridge
Rust Core (EPUB, TTS, Cache, Manifest)
```

### Performance Targets
- TTS synthesis: ≥1.2x realtime (mock implementation)
- Paragraph gaps: ≤200ms with prebuffering
- Memory usage: <512MB per book
- Storage: ~1-3GB audio cache per book

### Supported Platforms
- ✅ Android
- ✅ Desktop (macOS, Windows, Linux)
- ✅ Web
- 🚧 iOS (planned for v0.1)

### Privacy & Security
- No user accounts or cloud sync
- No telemetry or analytics
- All processing happens locally
- Only network requests: downloading public domain books
- Data stays on device

### Known Limitations
- Mock TTS implementation (real Piper/ONNX integration in next version)
- Basic reading mode (enhanced UI planned for v0.1)
- No background audio (requires audio_service integration)
- No iOS App Store distribution yet
- Limited error handling for edge cases

### Testing Coverage
- Rust unit tests: Core functionality
- Flutter unit tests: UI components and state management
- E2E tests: Complete user journeys with Playwright
- Manual testing: Book search → download → playback flow

### Documentation
- Comprehensive README with setup instructions
- Product Requirements Document (PRD)
- Code documentation and comments
- Test suite documentation