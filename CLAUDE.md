# Claude AI Development Guide - SailorBook

## 🤖 Overview

This file contains comprehensive guidelines for Claude AI agents working on the SailorBook project. It serves as the primary reference for understanding project structure, development practices, and coordination between multiple AI agents.

## 📋 Project Summary

**SailorBook** is a privacy-first reading and listening app for public-domain books that:
- Downloads books from Open Library/Project Gutenberg
- Parses EPUBs locally with smart text normalization  
- Generates human-like audio using local AI TTS (Piper/ONNX)
- Provides seamless audio playback with smart caching
- Works entirely offline after initial download

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                Flutter UI                        │
│     (Material 3, Cross-platform)               │
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

## 📁 Project Structure

```
SailorBook/
├── CLAUDE.md                    # This file - Main AI guide
├── FEATURES.md                  # Core features roadmap
├── .claude/                     # Claude Code configuration
│   ├── agents/                  # Specialized AI agent guides
│   │   ├── ai-orchestration.md # Multi-agent coordination
│   │   ├── linting.md          # Code quality standards
│   │   ├── playwright.md       # E2E testing guide
│   │   ├── testing.md          # Unit testing patterns
│   │   └── ui-ux.md           # Material 3 design guide
│   └── config/                  # Claude Code settings
├── apps/app_flutter/            # Flutter application
│   ├── lib/
│   │   ├── models/              # Data models (Book, Voice)
│   │   ├── services/            # Business logic
│   │   ├── controllers/         # State management
│   │   ├── views/               # UI screens
│   │   ├── widgets/             # Reusable components
│   │   └── themes/              # UI theming
│   └── pubspec.yaml
├── crates/pdreader_core/        # Rust core library
│   └── src/
│       ├── epub/                # EPUB parsing
│       ├── tts/                 # Text-to-speech
│       ├── cache/               # Audio caching
│       └── manifest/            # Book management
├── tests/playwright/            # E2E testing
│   ├── tests/                   # Test specifications
│   ├── FAILED_TESTS_ANALYSIS.md # Implementation roadmap
│   └── playwright.config.ts
└── scripts/                     # Build & deployment
```

## 🔧 Development Status

### ✅ Completed Components
- **Flutter App Structure**: Material 3 UI, responsive design
- **Rust Core Architecture**: Complete module structure
- **E2E Testing Framework**: 39 Playwright tests (12 passing)
- **Documentation**: Comprehensive README, PRD, analysis docs
- **CI/CD**: GitHub Actions, comprehensive .gitignore

### 🔄 In Progress
- **Flutter UI Integration**: Adding test identifiers and API integration
- **Search Functionality**: Open Library API integration
- **Download System**: EPUB downloading and local storage
- **TTS Integration**: Piper ONNX runtime integration

### 📋 Priority Implementation Order
1. **Critical**: Flutter glass pane visibility fixes
2. **High**: Search API and download functionality
3. **Medium**: Player controls and audio system
4. **Low**: Advanced features and optimizations

## 🎯 Development Guidelines

### Code Quality Standards
- **Flutter**: Follow Material 3 design patterns
- **Rust**: Use idiomatic Rust with comprehensive error handling
- **Testing**: All new features require E2E test coverage
- **Documentation**: Update relevant CLAUDE_*.md files

### Key Principles
1. **Privacy First**: No user data collection, offline-capable
2. **Performance**: TTS ≥1.2× realtime, <200ms gaps between paragraphs
3. **Cross-Platform**: Flutter for all platforms (mobile, desktop, web)
4. **Test-Driven**: E2E tests define expected behavior

## 📚 Specialized Guides

### Core Development
- 📋 **[.claude/agents/linting.md](.claude/agents/linting.md)**: Code quality, formatting, and style standards
- 🧪 **[.claude/agents/testing.md](.claude/agents/testing.md)**: Unit testing strategies and patterns  
- 🎭 **[.claude/agents/playwright.md](.claude/agents/playwright.md)**: E2E testing with Playwright

### UI/UX Development  
- 🎨 **[.claude/agents/ui-ux.md](.claude/agents/ui-ux.md)**: Design system, Material 3 guidelines

### AI Coordination
- 🤝 **[.claude/agents/ai-orchestration.md](.claude/agents/ai-orchestration.md)**: Multi-agent coordination and task delegation

### Feature Planning
- 🎯 **[FEATURES.md](FEATURES.md)**: Core features roadmap and implementation priorities

## 🚀 Quick Start for Claude Agents

### Before Making Changes
1. **Read Relevant Guides**: Check specialized `.claude/agents/` files for your domain
2. **Check Feature Roadmap**: Review `FEATURES.md` for current priorities
3. **Check Test Status**: Review `tests/playwright/FAILED_TESTS_ANALYSIS.md`
4. **Understand Architecture**: Review this file and PRD.md

### Common Tasks

#### Adding Flutter UI Components
```bash
# 1. Check UI guidelines
cat .claude/agents/ui-ux.md

# 2. Add component with test IDs
# Follow Material 3 patterns in themes/app_theme.dart

# 3. Run tests
cd tests/playwright && npx playwright test --headed
```

#### Implementing API Integration
```bash
# 1. Check service patterns
find apps/app_flutter/lib/services -name "*.dart"

# 2. Add to book_service.dart following existing patterns
# 3. Update controllers with proper state management
# 4. Add E2E test coverage
```

#### Adding Rust Functionality
```bash
# 1. Check existing patterns
find crates/pdreader_core/src -name "*.rs"

# 2. Add to appropriate module
# 3. Update FFI bridge in generated/native.dart
# 4. Test with cargo test
```

## 🧪 Testing Strategy

### Current Test Coverage
- **Basic Functionality**: 6/6 tests ✅ (App loading, network, performance)
- **Working Features**: 6/6 tests ✅ (Architecture, responsiveness)
- **App Functionality**: 0/10 tests ❌ (Requires Flutter UI test IDs)
- **E2E Flows**: 0/7 tests ❌ (Requires search/download implementation)
- **Search & Download**: 0/6 tests ❌ (Requires API integration)

### Test-First Development
1. **Check failing tests** in `FAILED_TESTS_ANALYSIS.md`
2. **Implement features** to make tests pass
3. **Verify** with `npx playwright test --headed`
4. **Update documentation** as needed

## 🔍 Debugging Guidelines

### Common Issues
- **Flutter Glass Pane**: Hidden element causing interaction failures
- **Test Identifiers**: Missing `key: Key('test-id')` in widgets
- **API Integration**: Mock responses work, need real implementation
- **Coordinate Clicking**: Flutter web requires specific interaction patterns

### Debugging Commands
```bash
# Start Flutter app for testing
cd apps/app_flutter && flutter run -d web-server --web-port=3000

# Run specific test suite
cd tests/playwright && npx playwright test tests/basic.spec.ts --headed

# View test results
npx playwright show-report

# Check Flutter build
cd apps/app_flutter && flutter doctor
```

## 📊 Performance Targets

### Flutter App
- **Load Time**: <10 seconds for initial startup
- **Memory Usage**: <512MB typical usage
- **Responsiveness**: <300ms UI interactions

### Rust Core
- **TTS Speed**: ≥1.2× realtime on typical hardware
- **Audio Gaps**: <200ms between paragraphs
- **Cache Efficiency**: LRU with hash-based storage

## 🔐 Security & Privacy

### Data Handling
- **No User Accounts**: Everything local
- **No Telemetry**: Zero analytics or tracking
- **Network Usage**: Only for downloading public domain books
- **Local Storage**: All user data stays on device

### API Usage
- **Open Library**: Public API for book search
- **Internet Archive**: Public API for EPUB downloads
- **No Authentication**: Required for privacy

## 📝 Documentation Standards

### Code Documentation
- **Flutter**: DartDoc comments for public APIs
- **Rust**: Rustdoc comments with examples
- **Tests**: Clear test descriptions and comments

### File Updates
- **Always Update**: Relevant CLAUDE_*.md files when changing behavior
- **Version Control**: Commit documentation changes with code
- **Consistency**: Follow established patterns and terminology

## 🎯 Success Metrics

### Immediate Goals
- **All E2E Tests Passing**: 39/39 tests green
- **Core Functionality**: Search, download, basic playback working
- **Cross-Platform**: Web and desktop builds working

### Long-Term Goals
- **Performance**: Meeting all performance targets
- **User Experience**: Smooth, intuitive interface
- **Reliability**: Robust error handling and offline capability

## 🚨 Critical Reminders

1. **Always run tests** before committing changes
2. **Check FAILED_TESTS_ANALYSIS.md** for current implementation needs
3. **Follow Material 3 guidelines** for UI components
4. **Add test identifiers** to all interactive elements
5. **Update documentation** when changing behavior
6. **Maintain privacy-first** approach in all implementations

## 📞 Getting Help

### Resource Priority
1. **This file (CLAUDE.md)**: Overall guidance and architecture
2. **FEATURES.md**: Core features roadmap and priorities
3. **Specialized .claude/agents/ files**: Domain-specific guidelines
4. **FAILED_TESTS_ANALYSIS.md**: Current implementation requirements
5. **PRD.md**: Product requirements and user stories
6. **README.md**: Setup and general project information

### Before Asking for Help
- Check relevant .claude/agents/ files for your domain
- Review FEATURES.md for current priorities
- Review test failures and analysis
- Understand the current implementation status
- Consider cross-platform implications

---

**Last Updated**: 2025-08-28  
**Version**: 1.0.0  
**Status**: Active Development

*This guide is continuously updated. Always refer to the latest version when working on SailorBook.*