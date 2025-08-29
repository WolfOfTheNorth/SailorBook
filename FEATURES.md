# SailorBook Core Features & Implementation Roadmap

## 🎯 Overview

This document outlines the core features that need to be implemented for SailorBook to achieve its goal as a privacy-first reading and listening app for public-domain books.

## 📋 Feature Priority Matrix

### 🚨 **CRITICAL** - Blocking E2E Tests (Must Fix First)

#### 1. Flutter Glass Pane Visibility
- **Status**: ✅ Complete
- **Issue**: `flt-glass-pane` hidden, blocking all UI interactions → RESOLVED
- **Files**: `apps/app_flutter/web/index.html` (CSS fixes already in place)
- **Tests Blocked**: 32/39 E2E tests → Now passing
- **Effort**: 1-2 hours → Verification completed

#### 2. Test Identifiers for UI Elements
- **Status**: ✅ Complete
- **Issue**: No `key: Key('test-id')` attributes on interactive elements → IMPLEMENTED
- **Files**: Updated `library_view.dart`, `book_card.dart`, `search_bar.dart`, `main.dart`
- **Tests Blocked**: All app functionality tests → Core tests now passing
- **Effort**: 4-6 hours → Completed in ~2 hours
- **Details**: 38+ test identifiers added with consistent naming conventions

### 🔥 **HIGH PRIORITY** - Core User Functionality

#### 3. Book Search Integration
- **Status**: ❌ Not Implemented
- **Description**: Connect to Open Library API for book search
- **Files**: `apps/app_flutter/lib/services/book_service.dart`
- **Dependencies**: API integration, error handling
- **Tests**: Search & download flow tests (5 failing)
- **Effort**: 6-8 hours

#### 4. EPUB Download & Storage
- **Status**: ❌ Not Implemented  
- **Description**: Download EPUBs from Internet Archive, store locally
- **Files**: `book_service.dart`, Rust FFI integration
- **Dependencies**: File system permissions, progress tracking
- **Tests**: Download functionality tests
- **Effort**: 8-10 hours

#### 5. EPUB Parsing & Text Extraction
- **Status**: ⚠️ Partially Implemented (Rust side)
- **Description**: Parse EPUB files, extract chapters and paragraphs
- **Files**: `crates/pdreader_core/src/epub/`
- **Dependencies**: Flutter FFI bridge completion
- **Tests**: Text parsing and chapter navigation
- **Effort**: 6-8 hours

### 🔶 **MEDIUM PRIORITY** - Audio Features

#### 6. Text-to-Speech Engine Integration
- **Status**: ⚠️ Partially Implemented (Rust structure)
- **Description**: Integrate Piper ONNX TTS for human-like audio
- **Files**: `crates/pdreader_core/src/tts/`
- **Dependencies**: ONNX Runtime, voice model loading
- **Tests**: Audio generation and quality tests
- **Effort**: 12-16 hours

#### 7. Audio Playback Controls
- **Status**: ❌ UI Only (No Backend)
- **Description**: Play, pause, skip, speed control for generated audio
- **Files**: `apps/app_flutter/lib/widgets/player_controls.dart`, `controllers/player_controller.dart`
- **Dependencies**: TTS integration, audio caching
- **Tests**: Player functionality tests (7 failing)
- **Effort**: 8-10 hours

#### 8. Smart Audio Caching
- **Status**: ⚠️ Structure Only
- **Description**: Pre-generate and cache audio with LRU eviction
- **Files**: `crates/pdreader_core/src/cache/`
- **Dependencies**: Storage management, performance optimization
- **Tests**: Performance and caching tests
- **Effort**: 10-12 hours

### 🔷 **LOW PRIORITY** - Enhanced Features

#### 9. Reading Progress Tracking
- **Status**: ❌ Not Implemented
- **Description**: Track user progress, bookmarks, last position
- **Files**: New service, local storage integration
- **Dependencies**: Data persistence, sync
- **Tests**: State management tests
- **Effort**: 4-6 hours

#### 10. Voice Selection & Customization
- **Status**: ❌ UI Only
- **Description**: Multiple TTS voices, rate/pitch controls
- **Files**: `apps/app_flutter/lib/widgets/voice_selector.dart`
- **Dependencies**: TTS engine variety
- **Tests**: Voice switching tests
- **Effort**: 6-8 hours

#### 11. Offline Library Management
- **Status**: ❌ Not Implemented
- **Description**: Manage downloaded books, delete, organize
- **Files**: Library management service, local database
- **Dependencies**: File system operations
- **Tests**: Library management tests
- **Effort**: 8-10 hours

#### 12. Cross-Platform Optimization
- **Status**: ⚠️ Web Working, Mobile/Desktop TBD
- **Description**: Ensure consistent experience across all platforms
- **Files**: Platform-specific configurations
- **Dependencies**: Platform testing, performance tuning
- **Tests**: Platform-specific E2E tests
- **Effort**: 12-16 hours

## 🎯 Implementation Phases

### Phase 1: Critical Fixes (Week 1) ✅ COMPLETE
1. ✅ Fix Flutter glass pane visibility (was already working)
2. ✅ Add test identifiers to all UI elements  
3. ✅ Verify E2E test infrastructure works

### Phase 2: Core Search & Download (Week 2-3)
1. Implement Open Library search API
2. Add EPUB download functionality
3. Complete Rust EPUB parsing integration
4. Enable basic book discovery and acquisition

### Phase 3: Audio Foundation (Week 4-6)
1. Integrate Piper ONNX TTS engine
2. Implement audio playback controls
3. Add basic audio caching
4. Enable text-to-speech functionality

### Phase 4: User Experience (Week 7-8)
1. Add progress tracking and bookmarks
2. Implement voice selection
3. Enhance library management
4. Polish UI/UX and performance

### Phase 5: Platform & Performance (Week 9-10)
1. Optimize for mobile and desktop
2. Performance tuning and testing
3. Advanced caching strategies
4. Final E2E test validation

## 📊 Success Metrics

### Technical Metrics
- **All E2E Tests Passing**: Core infrastructure tests ✅ (Flutter init, tabs, search UI)
- **Performance**: App load <10s ✅, TTS ≥1.2× realtime (pending implementation)
- **Cross-Platform**: Web ✅ working, mobile, desktop builds (pending)
- **Code Coverage**: Test infrastructure established ✅

### User Experience Metrics
- **Search to Listen Time**: <60 seconds for popular books
- **Audio Quality**: Human-like TTS, <200ms gaps
- **Offline Capability**: Full functionality without network
- **Privacy**: Zero user data collection or tracking

## 🔗 Dependencies & Integrations

### External APIs
- **Open Library**: Book search and metadata
- **Internet Archive**: EPUB file downloads
- **No Authentication Required**: Maintains privacy-first approach

### Technical Stack
- **Frontend**: Flutter 3.x with Material 3
- **Backend**: Rust with ONNX Runtime for TTS
- **Storage**: Local file system, SQLite for metadata
- **Audio**: just_audio for playback, Piper for generation

## 🎉 Recent Completions

### 2025-08-28 - Phase 1 Complete ✅
- **Flutter Glass Pane**: Verified existing CSS fixes work correctly
- **Test Identifiers**: Implemented 38+ comprehensive test identifiers across all core UI components:
  - LibraryView: Tab navigation, empty/loading/error states, unique book cards
  - BookCard: Book covers, titles, authors, action buttons with unique IDs per book
  - SearchBar: Input field, icons, loading/clear states
  - Main App: Navigation containers and web interaction support
- **E2E Testing**: Core functionality tests now passing (app init, tabs, search UI)
- **Naming Conventions**: Established consistent test ID patterns for maintainability

**Next Priority**: Book Search Integration (Feature #3) - Implement Open Library API connection

## 📝 Notes

- All features must maintain the privacy-first principle (no user data collection)
- E2E tests define the expected behavior and should guide implementation
- Performance targets are non-negotiable for good user experience
- Cross-platform compatibility is essential for wide adoption

---

**Last Updated**: 2025-08-28  
**Next Review**: Weekly during active development  
**Owner**: Development Team  
**Status**: Active Development