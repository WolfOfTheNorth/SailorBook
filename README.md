# Public-Domain Reader (SailorBook)

A privacy-first reading and listening app for public-domain books. Download books from public sources, parse EPUBs locally, and generate human-like audio entirely on-device using local AI TTS.

## 🚀 Features (MVP v0.0.1)

- 📚 **Library Management**: Search and download public-domain books from Open Library/Project Gutenberg
- 📖 **EPUB Processing**: Parse chapters and paragraphs locally with smart text normalization
- 🎙️ **Local TTS**: Generate audio using bundled AI voice models (Piper/ONNX Runtime)
- ⏯️ **Audio Player**: Basic controls (play/pause, next/prev paragraph, speed adjustment, seek back)
- 💾 **Smart Caching**: LRU audio cache with prebuffering for seamless playback
- 🔒 **Privacy-First**: No servers, no tracking, everything works offline after download
- 📱 **Cross-Platform**: Flutter app for Android, Desktop (macOS/Windows/Linux), and Web

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                Flutter UI                        │
│  (Material 3, Riverpod, go_router)             │
└─────────────────┬───────────────────────────────┘
                  │ FFI Bridge
┌─────────────────▼───────────────────────────────┐
│              Rust Core                          │
│  • EPUB parsing & normalization                │
│  • TTS synthesis (Piper + ONNX Runtime)       │
│  • Audio caching & prebuffering               │
│  • Manifest management                        │
└─────────────────────────────────────────────────┘
```

## 🛠️ Development Setup

### Prerequisites

- **Flutter SDK** 3.16.0+
- **Rust** 1.70.0+
- **Node.js** 18+ (for testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/davebhardwaj/SailorBook.git
   cd SailorBook
   ```

2. **Install Flutter dependencies**
   ```bash
   cd apps/app_flutter
   flutter pub get
   ```

3. **Build Rust core**
   ```bash
   cd ../../crates/pdreader_core
   cargo build --release
   ```

4. **Generate Flutter-Rust bridge**
   ```bash
   cargo run --bin codegen
   ```

5. **Install test dependencies** (optional)
   ```bash
   cd ../../tests/playwright
   npm install
   npx playwright install
   ```

### Running the App

**Desktop (recommended for development)**
```bash
cd apps/app_flutter
flutter run -d macos  # or -d windows, -d linux
```

**Web**
```bash
flutter run -d web-server --web-port=3000
```

**Android** (requires Android device/emulator)
```bash
flutter run -d android
```

## 🧪 Testing

### Unit Tests
```bash
# Flutter tests
cd apps/app_flutter
flutter test

# Rust tests
cd ../../crates/pdreader_core
cargo test
```

### Integration Tests (Playwright)
```bash
cd tests/playwright

# Run all tests headlessly
npm run test

# Run tests visually (with browser UI)
npx playwright test --headed

# Run specific test suite
npx playwright test tests/basic.spec.ts --headed

# View test report
npx playwright show-report
```

#### Test Status Summary
- ✅ **Basic App Tests**: 6/6 passing - Flutter loading, interactions, responsiveness
- ✅ **Working Features**: 6/6 passing - Network, performance, architecture 
- ❌ **App Functionality**: 0/10 passing - Requires Flutter UI test IDs (see `FAILED_TESTS_ANALYSIS.md`)
- ❌ **E2E Flows**: 0/7 passing - Requires search/download implementation
- ❌ **Search & Download**: 0/6 passing - Requires API integration

📋 **Next Steps**: See `tests/playwright/FAILED_TESTS_ANALYSIS.md` for detailed implementation requirements.

### Manual Testing
1. Start the app: `flutter run -d web-server --web-port=3000`
2. Navigate to http://localhost:3000
3. Search for "Alice Adventures Wonderland"
4. Download and play the book

## 📁 Project Structure

```
SailorBook/
├── apps/
│   └── app_flutter/          # Flutter application
│       ├── lib/
│       │   ├── models/       # Data models
│       │   ├── services/     # Business logic
│       │   ├── controllers/  # State management (Riverpod)
│       │   ├── views/        # UI screens
│       │   ├── widgets/      # Reusable components
│       │   └── themes/       # UI theming
│       └── pubspec.yaml
├── crates/
│   └── pdreader_core/        # Rust core library
│       ├── src/
│       │   ├── epub/         # EPUB parsing & normalization
│       │   ├── tts/          # Text-to-speech engine
│       │   ├── cache/        # Audio caching system
│       │   └── manifest/     # Book manifest management
│       └── Cargo.toml
├── tests/
│   └── playwright/           # E2E tests
│       ├── tests/            # Test specifications
│       ├── pages/            # Page Object Models
│       ├── fixtures/         # Test data
│       ├── setup/            # Test setup & teardown
│       ├── test-results/     # Test outputs & screenshots
│       └── FAILED_TESTS_ANALYSIS.md  # Implementation roadmap
└── PRD.md                    # Product Requirements Document
```

## 🎯 User Flows

### 1. Discovery & Download
1. Open app → Empty library with "Browse Books" button
2. Tap Search tab → Search "Alice Wonderland"
3. View results → Tap book → See details & download button
4. Download → EPUB processed → Book appears in library

### 2. Listening Experience
1. Tap "Listen" → Player opens with book cover
2. Tap play → TTS generates audio → Paragraph displays
3. Audio prebuffers next 2-3 paragraphs
4. Controls: next/prev paragraph, speed (0.8×-2.5×), seek back 10s
5. Auto-advance between paragraphs with <200ms gaps

### 3. Offline Usage
1. Download books once → Everything works offline
2. Position saved automatically → Resume on app restart
3. Audio cached by content hash → Instant replay

## 🔧 Technical Details

### TTS Pipeline
1. **Text Processing**: EPUB → chapters → paragraphs → normalization
2. **Audio Generation**: Piper ONNX model → PCM/OGG audio
3. **Caching**: Hash-based storage with LRU eviction
4. **Prebuffering**: Generate next N paragraphs while playing current

### Performance Targets
- **TTS Speed**: ≥1.2× realtime on typical laptop
- **Gap Between Paragraphs**: ≤200ms average with prebuffering
- **Memory Usage**: <512MB for average book with audio cache
- **Storage**: ~1-3GB audio cache per book

### Privacy & Offline-First
- No user accounts or cloud sync
- No telemetry or analytics
- Only network: downloading public domain books
- All TTS processing happens locally
- Data stays on device

## 🚦 Development Status & Roadmap

### Current Status (v0.0.1-alpha)
✅ **Completed:**
- Flutter app architecture with Material 3 UI
- Rust core library structure
- Comprehensive Playwright test suite (39 tests)
- E2E testing framework with visual validation
- Project documentation and development setup

🔄 **In Progress:**
- Flutter UI test identifier integration
- Search API integration with Open Library
- EPUB download and storage functionality
- TTS engine integration with Piper ONNX

### Roadmap
- **v0.0.1** (MVP): Core reading/listening loop
- **v0.1**: Reading mode, sentence highlighting, sleep timer, iOS support  
- **v0.2**: Background audio, download manager, jurisdiction filters
- **v0.3**: Pro features ($9.99), voice packs, audio export

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Voice Models**: Piper TTS by Mike Hansen
- **Public Domain Sources**: Project Gutenberg, Internet Archive
- **Core Technologies**: Flutter, Rust, ONNX Runtime
- **UI Inspiration**: Material Design 3, shadcn/ui principles

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Workflow

1. **Setup**: Follow installation instructions above
2. **Development**: Use `flutter run -d web-server` for hot reload
3. **Testing**: Run unit tests and E2E tests before committing
4. **Code Style**: Use `dart format` and `cargo fmt`
5. **Commits**: Use conventional commit messages

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/davebhardwaj/SailorBook/issues)
- **Discussions**: [GitHub Discussions](https://github.com/davebhardwaj/SailorBook/discussions)
- **Documentation**: [Wiki](https://github.com/davebhardwaj/SailorBook/wiki)

---

**Note**: This is an MVP implementation. Some features use mock implementations to demonstrate the architecture. Full TTS integration with ONNX Runtime will be completed in the next iteration.
