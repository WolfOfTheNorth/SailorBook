# Claude AI Testing Guide - SailorBook

## 🧪 Overview

This guide provides comprehensive testing strategies, patterns, and best practices for Claude AI agents working on SailorBook. It covers unit testing, integration testing, widget testing, and testing patterns for both Flutter and Rust components.

## 📋 Testing Philosophy

### Core Testing Principles
1. **Test-Driven Development**: Write tests before implementation when possible
2. **Comprehensive Coverage**: Aim for >80% code coverage with meaningful tests
3. **Fast Feedback**: Unit tests should run quickly and provide immediate feedback
4. **Realistic Testing**: Test real user scenarios, not just happy paths
5. **Maintainable Tests**: Tests should be easy to read, understand, and maintain

## 🎯 Testing Strategy Overview

```
Testing Pyramid for SailorBook:

┌─────────────────────────────┐
│      E2E Tests              │  <- Playwright (covered in CLAUDE_PLAYWRIGHT.md)
│   (User Journeys)          │
├─────────────────────────────┤
│    Integration Tests        │  <- Widget tests, API integration
│   (Component Interaction)   │
├─────────────────────────────┤
│      Unit Tests             │  <- Business logic, utilities
│   (Individual Functions)    │     (Largest layer)
└─────────────────────────────┘
```

## 🛠️ Flutter Testing

### Test Structure & Setup

#### Test File Organization
```
apps/app_flutter/test/
├── unit/
│   ├── models/
│   │   ├── book_test.dart
│   │   └── voice_test.dart
│   ├── services/
│   │   ├── book_service_test.dart
│   │   └── audio_service_test.dart
│   └── utils/
│       └── text_normalizer_test.dart
├── widget/
│   ├── book_card_test.dart
│   ├── player_controls_test.dart
│   └── search_bar_test.dart
├── integration/
│   ├── search_flow_test.dart
│   └── download_flow_test.dart
└── mocks/
    ├── mock_book_service.dart
    └── mock_audio_service.dart
```

#### Test Dependencies Setup
```yaml
# pubspec.yaml - test dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.7
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
  patrol: ^2.0.0  # For complex widget interactions
```

### Unit Testing Patterns

#### Model Testing
```dart
// test/unit/models/book_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdreader/models/book.dart';

void main() {
  group('Book Model', () {
    test('should create Book from valid JSON', () {
      // Arrange
      final json = {
        'key': '/works/OL123456W',
        'title': 'Alice\'s Adventures in Wonderland',
        'author_name': ['Lewis Carroll'],
        'first_publish_year': 1865,
        'cover_i': 123456,
        'ia': ['alice-wonderland-001'],
      };

      // Act
      final book = Book.fromOpenLibrary(json);

      // Assert
      expect(book.id, equals('OL123456W'));
      expect(book.title, equals('Alice\'s Adventures in Wonderland'));
      expect(book.author, equals('Lewis Carroll'));
      expect(book.publishYear, equals(1865));
      expect(book.coverUrl, contains('123456'));
      expect(book.iaId, equals('alice-wonderland-001'));
    });

    test('should handle missing fields gracefully', () {
      // Arrange
      final json = {
        'key': '/works/OL123456W',
        'title': 'Test Book',
        // Missing author_name, cover_i, etc.
      };

      // Act
      final book = Book.fromOpenLibrary(json);

      // Assert
      expect(book.id, equals('OL123456W'));
      expect(book.title, equals('Test Book'));
      expect(book.author, equals('Unknown Author'));
      expect(book.coverUrl, isNull);
    });

    test('should validate required fields', () {
      // Arrange
      final invalidJson = <String, dynamic>{};

      // Act & Assert
      expect(
        () => Book.fromOpenLibrary(invalidJson),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

#### Service Testing with Mocks
```dart
// test/unit/services/book_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdreader/services/book_service.dart';
import 'package:pdreader/models/book.dart';

import 'book_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('BookService', () {
    late BookService bookService;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      bookService = BookService(client: mockHttpClient);
    });

    group('searchBooks', () {
      test('should return list of books on successful search', () async {
        // Arrange
        const query = 'alice wonderland';
        final mockResponse = http.Response('''
        {
          "docs": [
            {
              "key": "/works/OL123456W",
              "title": "Alice's Adventures in Wonderland",
              "author_name": ["Lewis Carroll"],
              "first_publish_year": 1865,
              "cover_i": 123456,
              "ia": ["alice-wonderland-001"]
            }
          ]
        }
        ''', 200);

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final books = await bookService.searchBooks(query);

        // Assert
        expect(books, hasLength(1));
        expect(books.first.title, equals('Alice\'s Adventures in Wonderland'));
        expect(books.first.author, equals('Lewis Carroll'));

        // Verify HTTP call was made correctly
        verify(mockHttpClient.get(
          Uri.parse('https://openlibrary.org/search.json?q=alice%20wonderland&limit=20'),
          headers: {'Accept': 'application/json'},
        )).called(1);
      });

      test('should throw BookServiceException on network error', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(const SocketException('Network unreachable'));

        // Act & Assert
        expect(
          () => bookService.searchBooks('test'),
          throwsA(isA<BookServiceException>()
              .having((e) => e.message, 'message', contains('Network'))),
        );
      });

      test('should throw BookServiceException on HTTP error', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
          () => bookService.searchBooks('test'),
          throwsA(isA<BookServiceException>()
              .having((e) => e.message, 'message', contains('404'))),
        );
      });

      test('should handle empty search results', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('{"docs": []}', 200));

        // Act
        final books = await bookService.searchBooks('nonexistent');

        // Assert
        expect(books, isEmpty);
      });
    });

    group('downloadBook', () {
      test('should download and save book successfully', () async {
        // Arrange
        final book = Book(
          id: 'test-id',
          title: 'Test Book',
          author: 'Test Author',
          iaId: 'test-archive-id',
        );

        final mockEpubResponse = http.Response('mock epub content', 200);
        when(mockHttpClient.get(
          Uri.parse('https://archive.org/download/test-archive-id/test-archive-id.epub'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => mockEpubResponse);

        // Act
        await bookService.downloadBook(book);

        // Assert
        verify(mockHttpClient.get(
          Uri.parse('https://archive.org/download/test-archive-id/test-archive-id.epub'),
          headers: {'Accept': 'application/epub+zip'},
        )).called(1);

        // Verify book was saved (would need to mock file system)
        final savedBooks = await bookService.getDownloadedBooks();
        expect(savedBooks, contains(book));
      });
    });
  });
}
```

### Widget Testing

#### Simple Widget Tests
```dart
// test/widget/book_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdreader/widgets/book_card.dart';
import 'package:pdreader/models/book.dart';

void main() {
  group('BookCard Widget', () {
    late Book testBook;

    setUp(() {
      testBook = const Book(
        id: 'test-id',
        title: 'Test Book Title',
        author: 'Test Author',
        coverUrl: 'https://example.com/cover.jpg',
      );
    });

    testWidgets('should display book information correctly', (tester) async {
      // Arrange
      bool wasTapped = false;
      bool wasDownloaded = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCard(
              book: testBook,
              onTap: () => wasTapped = true,
              onDownload: () => wasDownloaded = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Book Title'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      expect(find.byKey(Key('book-card-${testBook.id}')), findsOneWidget);
      expect(find.byKey(Key('download-btn-${testBook.id}')), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      // Arrange
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCard(
              book: testBook,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(Key('book-card-${testBook.id}')));
      await tester.pump();

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('should show listen button when book is downloaded', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCard(
              book: testBook,
              isDownloaded: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(Key('listen-btn-${testBook.id}')), findsOneWidget);
      expect(find.byKey(Key('download-btn-${testBook.id}')), findsNothing);
    });

    testWidgets('should handle missing cover image gracefully', (tester) async {
      // Arrange
      final bookWithoutCover = testBook.copyWith(coverUrl: null);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCard(book: bookWithoutCover),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
```

#### Complex Widget Testing with State
```dart
// test/widget/search_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:pdreader/views/search_view.dart';
import 'package:pdreader/services/book_service.dart';

import '../mocks/mock_book_service.dart';

void main() {
  group('SearchView Widget', () {
    late MockBookService mockBookService;

    setUp(() {
      mockBookService = MockBookService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<BookService>.value(
          value: mockBookService,
          child: const SearchView(),
        ),
      );
    }

    testWidgets('should display search input and empty state initially', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byKey(const Key('search-input')), findsOneWidget);
      expect(find.text('Search public domain books...'), findsOneWidget);
      expect(find.byKey(const Key('search-results-list')), findsNothing);
    });

    testWidgets('should perform search when text is submitted', (tester) async {
      // Arrange
      final testBooks = [
        const Book(id: '1', title: 'Test Book 1', author: 'Author 1'),
        const Book(id: '2', title: 'Test Book 2', author: 'Author 2'),
      ];

      when(mockBookService.searchBooks('alice'))
          .thenAnswer((_) async => testBooks);

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('search-input')), 'alice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(); // Wait for async operations

      // Assert
      verify(mockBookService.searchBooks('alice')).called(1);
      expect(find.byKey(const Key('search-results-list')), findsOneWidget);
      expect(find.text('Test Book 1'), findsOneWidget);
      expect(find.text('Test Book 2'), findsOneWidget);
    });

    testWidgets('should show loading state during search', (tester) async {
      // Arrange
      when(mockBookService.searchBooks(any))
          .thenAnswer((_) => Future.delayed(
                const Duration(milliseconds: 100),
                () => <Book>[],
              ));

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('search-input')), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(); // Don't wait for async completion

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Searching...'), findsOneWidget);
    });

    testWidgets('should show error state when search fails', (tester) async {
      // Arrange
      when(mockBookService.searchBooks(any))
          .thenThrow(const BookServiceException('Network error'));

      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.enterText(find.byKey(const Key('search-input')), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('error-message')), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byKey(const Key('retry-btn')), findsOneWidget);
    });

    testWidgets('should clear search when clear button is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byKey(const Key('search-input')), 'test');
      await tester.pump();

      // Act
      await tester.tap(find.byKey(const Key('clear-search')));
      await tester.pump();

      // Assert
      expect(find.text('test'), findsNothing);
      final textField = tester.widget<TextField>(find.byKey(const Key('search-input')));
      expect(textField.controller?.text, isEmpty);
    });
  });
}
```

## 🦀 Rust Testing

### Unit Test Structure

#### Basic Unit Tests
```rust
// crates/pdreader_core/src/epub/parser.rs
#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::{tempdir, NamedTempFile};
    
    #[test]
    fn test_parse_valid_epub() {
        // Arrange
        let temp_dir = tempdir().unwrap();
        let epub_path = temp_dir.path().join("test.epub");
        create_test_epub(&epub_path);
        
        // Act
        let parser = EpubParser::new(&epub_path).unwrap();
        let manifest = parser.parse().unwrap();
        
        // Assert
        assert_eq!(manifest.title, "Test Book");
        assert_eq!(manifest.author, "Test Author");
        assert!(!manifest.chapters.is_empty());
        assert_eq!(manifest.chapters.len(), 3);
    }
    
    #[test]
    fn test_parse_invalid_epub_returns_error() {
        // Arrange
        let invalid_path = Path::new("nonexistent.epub");
        
        // Act
        let result = EpubParser::new(invalid_path);
        
        // Assert
        assert!(result.is_err());
        match result.unwrap_err() {
            EpubError::FileNotFound { path } => {
                assert_eq!(path, "nonexistent.epub");
            }
            _ => panic!("Expected FileNotFound error"),
        }
    }
    
    #[test]
    fn test_normalize_text_removes_empty_lines() {
        // Arrange
        let input = "Line 1\n\n\nLine 2\n\n";
        let normalizer = TextNormalizer::new();
        
        // Act
        let result = normalizer.normalize(input);
        
        // Assert
        assert_eq!(result, "Line 1\nLine 2");
    }
    
    #[test]
    fn test_normalize_text_handles_special_characters() {
        // Arrange
        let input = "She said—"Hello there!"";
        let normalizer = TextNormalizer::new();
        
        // Act
        let result = normalizer.normalize(input);
        
        // Assert
        assert_eq!(result, "She said--\"Hello there!\"");
    }
    
    // Helper function for creating test EPUBs
    fn create_test_epub(path: &Path) {
        let epub_content = r#"
            <?xml version="1.0" encoding="UTF-8"?>
            <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
                <metadata>
                    <dc:title>Test Book</dc:title>
                    <dc:creator>Test Author</dc:creator>
                </metadata>
                <manifest>
                    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
                </manifest>
                <spine>
                    <itemref idref="chapter1"/>
                </spine>
            </package>
        "#;
        
        fs::write(path, epub_content).unwrap();
    }
}
```

#### Property-Based Testing
```rust
// Using proptest for property-based testing
#[cfg(test)]
mod property_tests {
    use super::*;
    use proptest::prelude::*;
    
    proptest! {
        #[test]
        fn test_text_normalizer_never_produces_longer_text(
            input in ".*"
        ) {
            let normalizer = TextNormalizer::new();
            let result = normalizer.normalize(&input);
            
            // Property: normalized text should never be longer than original
            prop_assert!(result.len() <= input.len());
        }
        
        #[test]
        fn test_text_normalizer_preserves_word_count(
            input in "[a-zA-Z ]+"
        ) {
            let normalizer = TextNormalizer::new();
            let result = normalizer.normalize(&input);
            
            let original_words: Vec<&str> = input.split_whitespace().collect();
            let normalized_words: Vec<&str> = result.split_whitespace().collect();
            
            // Property: word count should be preserved
            prop_assert_eq!(original_words.len(), normalized_words.len());
        }
    }
}
```

### Integration Tests
```rust
// crates/pdreader_core/tests/integration_test.rs
use pdreader_core::{EpubParser, TtsEngine, BookManifest};
use std::path::Path;
use tempfile::tempdir;

#[tokio::test]
async fn test_full_epub_to_audio_pipeline() {
    // Arrange
    let temp_dir = tempdir().unwrap();
    let epub_path = temp_dir.path().join("test.epub");
    let audio_dir = temp_dir.path().join("audio");
    
    create_test_epub(&epub_path);
    std::fs::create_dir(&audio_dir).unwrap();
    
    // Act
    let parser = EpubParser::new(&epub_path).unwrap();
    let manifest = parser.parse().unwrap();
    
    let tts_engine = TtsEngine::new().unwrap();
    let audio_files = tts_engine
        .synthesize_chapters(&manifest.chapters, &audio_dir)
        .await
        .unwrap();
    
    // Assert
    assert_eq!(audio_files.len(), manifest.chapters.len());
    
    for audio_file in &audio_files {
        assert!(audio_file.exists());
        assert!(audio_file.metadata().unwrap().len() > 0);
    }
}

#[test]
fn test_manifest_serialization_roundtrip() {
    // Arrange
    let original_manifest = BookManifest {
        id: "test-id".to_string(),
        title: "Test Book".to_string(),
        author: "Test Author".to_string(),
        chapters: vec![
            Chapter {
                id: 1,
                title: "Chapter 1".to_string(),
                content: "Chapter 1 content".to_string(),
                paragraphs: vec!["Paragraph 1".to_string()],
            },
        ],
    };
    
    // Act
    let serialized = serde_json::to_string(&original_manifest).unwrap();
    let deserialized: BookManifest = serde_json::from_str(&serialized).unwrap();
    
    // Assert
    assert_eq!(original_manifest.id, deserialized.id);
    assert_eq!(original_manifest.title, deserialized.title);
    assert_eq!(original_manifest.chapters.len(), deserialized.chapters.len());
}
```

## 🎯 Test Organization & Best Practices

### Test Naming Conventions
```dart
// ✅ Good test names - describe behavior
test('should return empty list when no books match search query', () {});
test('should throw BookServiceException when network is unavailable', () {});
test('should display loading indicator while downloading book', () {});

// ❌ Poor test names - describe implementation
test('searchBooks returns list', () {});
test('http client throws exception', () {});
test('widget shows progress indicator', () {});
```

### Test Structure (AAA Pattern)
```dart
test('should calculate correct reading time for chapter', () {
  // Arrange (Given)
  final chapter = Chapter(
    content: 'This is test content with exactly fifty words...',
    wordCount: 50,
  );
  final calculator = ReadingTimeCalculator(wordsPerMinute: 200);
  
  // Act (When)
  final result = calculator.calculateReadingTime(chapter);
  
  // Assert (Then)
  expect(result.inSeconds, equals(15)); // 50 words / 200 wpm * 60 sec
});
```

### Mock Objects
```dart
// test/mocks/mock_book_service.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdreader/services/book_service.dart';

@GenerateMocks([BookService])
class MockBookService extends Mock implements BookService {}

// Custom mock with preset behaviors
class FakeBookService implements BookService {
  final List<Book> _searchResults;
  final Duration _delay;
  final Exception? _exception;
  
  FakeBookService({
    List<Book> searchResults = const [],
    Duration delay = Duration.zero,
    Exception? exception,
  })  : _searchResults = searchResults,
        _delay = delay,
        _exception = exception;
  
  @override
  Future<List<Book>> searchBooks(String query) async {
    await Future.delayed(_delay);
    
    if (_exception != null) {
      throw _exception!;
    }
    
    return _searchResults
        .where((book) => 
            book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.author.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
```

## 📊 Test Coverage & Metrics

### Coverage Goals
- **Unit Tests**: >90% coverage for business logic
- **Widget Tests**: >80% coverage for UI components
- **Integration Tests**: Cover critical user paths
- **E2E Tests**: Cover complete user journeys

### Running Coverage Analysis
```bash
# Flutter coverage
cd apps/app_flutter
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Rust coverage (using tarpaulin)
cd crates/pdreader_core
cargo tarpaulin --out Html --output-dir coverage
open coverage/tarpaulin-report.html
```

### Coverage Analysis Script
```bash
#!/bin/bash
# scripts/test-coverage.sh

echo "🧪 Running comprehensive test coverage analysis..."

# Flutter tests
echo "📱 Running Flutter tests..."
cd apps/app_flutter
flutter test --coverage --reporter json > test_results.json

# Extract coverage percentage
FLUTTER_COVERAGE=$(lcov --summary coverage/lcov.info | grep 'lines......:' | awk '{print $2}')
echo "📊 Flutter coverage: $FLUTTER_COVERAGE"

# Rust tests  
echo "🦀 Running Rust tests..."
cd ../../crates/pdreader_core
cargo tarpaulin --out Json --output-dir coverage

# Extract coverage percentage
RUST_COVERAGE=$(jq '.files | map(.summary.lines.percent) | add / length' coverage/tarpaulin-report.json)
echo "📊 Rust coverage: ${RUST_COVERAGE}%"

# Check coverage thresholds
if (( $(echo "$FLUTTER_COVERAGE < 80" | bc -l) )); then
  echo "❌ Flutter coverage below threshold (80%)"
  exit 1
fi

if (( $(echo "$RUST_COVERAGE < 90" | bc -l) )); then
  echo "❌ Rust coverage below threshold (90%)"
  exit 1
fi

echo "✅ All coverage thresholds met!"
```

## 🚨 Common Testing Issues & Solutions

### Issue: Flaky Tests
```dart
// ❌ Flaky test - depends on timing
test('should show loading then results', () async {
  await tester.tap(find.byKey('search-btn'));
  expect(find.byType(CircularProgressIndicator), findsOneWidget); // Might fail
  
  await Future.delayed(Duration(milliseconds: 100));
  expect(find.text('Results'), findsOneWidget); // Timing dependent
});

// ✅ Robust test - uses pumpAndSettle
test('should show loading then results', () async {
  await tester.tap(find.byKey('search-btn'));
  await tester.pump(); // Process one frame
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  await tester.pumpAndSettle(); // Wait for all async operations
  expect(find.text('Results'), findsOneWidget);
});
```

### Issue: Testing Async Operations
```dart
// ✅ Proper async testing
testWidgets('should handle async download', (tester) async {
  // Arrange
  when(mockBookService.downloadBook(any))
      .thenAnswer((_) => Future.delayed(
            Duration(milliseconds: 500),
            () => Future.value(),
          ));

  await tester.pumpWidget(createTestWidget());

  // Act
  await tester.tap(find.byKey('download-btn'));
  await tester.pump(); // Start async operation

  // Assert loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for completion
  await tester.pumpAndSettle(Duration(seconds: 1));

  // Assert final state
  expect(find.text('Downloaded'), findsOneWidget);
});
```

### Issue: Testing Navigation
```dart
// ✅ Testing navigation with proper setup
testWidgets('should navigate to book details', (tester) async {
  // Arrange
  bool navigatedToDetails = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: BookCard(book: testBook),
      routes: {
        '/book-details': (context) {
          navigatedToDetails = true;
          return BookDetailsView(book: testBook);
        },
      },
    ),
  );

  // Act
  await tester.tap(find.byKey('book-card-${testBook.id}'));
  await tester.pumpAndSettle();

  // Assert
  expect(navigatedToDetails, isTrue);
  expect(find.byType(BookDetailsView), findsOneWidget);
});
```

## 📚 Testing Resources & Tools

### Recommended Packages
```yaml
# Flutter testing packages
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2          # Mocking framework
  mocktail: ^1.0.0         # Alternative mocking
  build_runner: ^2.4.7     # Code generation
  integration_test:        # Integration testing
    sdk: flutter
  patrol: ^2.0.0          # Advanced widget testing
  golden_toolkit: ^0.15.0 # Golden file testing
  alchemist: ^0.7.0       # Screenshot testing
```

### Test Utilities
```dart
// test/utils/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create MaterialApp wrapper for widget tests
Widget createTestApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

/// Helper to wait for specific widget to appear
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);
  
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    
    if (tester.any(finder)) {
      return;
    }
  }
  
  throw TimeoutException(
    'Widget not found within timeout',
    timeout,
  );
}

/// Helper to create test books
Book createTestBook({
  String id = 'test-id',
  String title = 'Test Book',
  String author = 'Test Author',
  String? coverUrl,
  bool isDownloaded = false,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    coverUrl: coverUrl,
    isDownloaded: isDownloaded,
  );
}
```

---

**Last Updated**: 2025-08-28  
**Status**: Active  
**Coverage Target**: >80% overall

*Follow these testing guidelines to ensure robust, maintainable, and comprehensive test coverage for SailorBook.*