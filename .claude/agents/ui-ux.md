# Claude AI UI/UX Design Guide - SailorBook

## 🎨 Overview

This guide defines the UI/UX standards, Material 3 implementation, and design patterns for Claude AI agents working on SailorBook's Flutter interface. All UI components must follow these guidelines for consistency and accessibility.

## 🎯 Design Philosophy

### Core Principles
1. **Privacy-First**: Clean, minimal design that feels trustworthy
2. **Reading-Focused**: Typography and layout optimized for long-form content
3. **Accessibility**: WCAG 2.1 AA compliance with keyboard and screen reader support
4. **Cross-Platform**: Consistent experience across mobile, tablet, and desktop
5. **Material 3**: Modern Google design language with dynamic color

## 🎨 Material 3 Implementation

### Color System

#### Theme Configuration
```dart
// themes/app_theme.dart - Already implemented
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1), // Indigo-500
        brightness: Brightness.light,
      ),
      typography: Typography.material2021(),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      typography: Typography.material2021(),
    );
  }
}
```

#### Color Usage Guidelines
```dart
// ✅ Use theme colors, not hardcoded colors
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Book Title',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
)

// ❌ Avoid hardcoded colors
Container(
  color: Colors.white,  // Bad - won't work in dark theme
  child: Text(
    'Book Title',
    style: TextStyle(color: Colors.black),  // Bad
  ),
)
```

### Typography Scale

```dart
// ✅ Typography implementation
class BookTypography {
  static TextStyle get displayLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.2,
  );
  
  static TextStyle get headlineLarge => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static TextStyle get titleLarge => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  // Reading-optimized styles
  static TextStyle get readingBody => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.6,
    fontFamily: 'Georgia', // Better for reading
  );
}
```

## 📱 Component Design Patterns

### Navigation Structure

```dart
// ✅ Main navigation implementation
class MainNavigation extends StatefulWidget {
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LibraryView(key: const Key('library-view')),
          SearchView(key: const Key('search-view')),
          SettingsView(key: const Key('settings-view')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() {
          _currentIndex = index;
        }),
        destinations: const [
          NavigationDestination(
            key: Key('nav-library'),
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            key: Key('nav-search'),
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            key: Key('nav-settings'),
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

### Book Card Design

```dart
// ✅ Consistent book card component
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final bool isDownloaded;
  
  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
    this.onDownload,
    this.isDownloaded = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('book-card-${book.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 90,
                  child: book.coverUrl != null
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                        )
                      : _buildCoverPlaceholder(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Action button
                    _buildActionButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCoverPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.book,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context) {
    if (isDownloaded) {
      return FilledButton.tonal(
        key: Key('listen-btn-${book.id}'),
        onPressed: onTap,
        child: const Text('Listen'),
      );
    } else {
      return OutlinedButton(
        key: Key('download-btn-${book.id}'),
        onPressed: onDownload,
        child: const Text('Download'),
      );
    }
  }
}
```

### Search Interface

```dart
// ✅ Search interface with proper UX
class SearchView extends StatefulWidget {
  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Book> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Books'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              key: const Key('search-input'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: 'Search public domain books...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    key: const Key('clear-search'),
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
              ],
              onSubmitted: _performSearch,
              onChanged: (value) {
                if (value.isEmpty) {
                  _clearSearch();
                }
              },
            ),
          ),
          
          // Results area
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              key: const Key('error-message'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('retry-btn'),
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64),
            SizedBox(height: 16),
            Text('No books found'),
            SizedBox(height: 8),
            Text('Try different search terms'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      key: const Key('search-results-list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return BookCard(
          key: Key('search-result-$index'),
          book: _searchResults[index],
          onTap: () => _openBookDetails(_searchResults[index]),
          onDownload: () => _downloadBook(_searchResults[index]),
        );
      },
    );
  }
}
```

## 📖 Reading Experience Design

### Player Interface

```dart
// ✅ Audio player with clean, focused design
class PlayerView extends StatefulWidget {
  final Book book;
  
  const PlayerView({
    Key? key,
    required this.book,
  }) : super(key: key);
  
  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('player-view'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('back-btn'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            key: const Key('voice-settings-btn'),
            icon: const Icon(Icons.settings_voice),
            onPressed: _openVoiceSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Book cover and info
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Large book cover
                  Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.book.coverUrl != null
                          ? Image.network(widget.book.coverUrl!, fit: BoxFit.cover)
                          : Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.book,
                                size: 80,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Book title and author
                  Text(
                    widget.book.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    widget.book.author,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Current chapter info
            Container(
              key: const Key('chapter-info'),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    'Chapter 1: Introduction',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paragraph 5 of 23',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Playback controls
            Expanded(
              flex: 2,
              child: _buildPlaybackControls(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaybackControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous paragraph
            IconButton.filledTonal(
              key: const Key('prev-paragraph-btn'),
              onPressed: _previousParagraph,
              iconSize: 32,
              icon: const Icon(Icons.skip_previous),
            ),
            
            // Play/Pause
            IconButton.filled(
              key: const Key('play-pause-btn'),
              onPressed: _togglePlayback,
              iconSize: 48,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            
            // Next paragraph
            IconButton.filledTonal(
              key: const Key('next-paragraph-btn'),
              onPressed: _nextParagraph,
              iconSize: 32,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Speed control
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Speed: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SegmentedButton<double>(
              key: const Key('speed-selector'),
              segments: const [
                ButtonSegment(value: 0.8, label: Text('0.8×')),
                ButtonSegment(value: 1.0, label: Text('1.0×')),
                ButtonSegment(value: 1.25, label: Text('1.25×')),
                ButtonSegment(value: 1.5, label: Text('1.5×')),
                ButtonSegment(value: 2.0, label: Text('2.0×')),
              ],
              selected: {_playbackSpeed},
              onSelectionChanged: (speeds) {
                if (speeds.isNotEmpty) {
                  _setPlaybackSpeed(speeds.first);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
```

## 🎯 Accessibility Guidelines

### Keyboard Navigation
```dart
// ✅ Keyboard navigation support
class AccessibleBookCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Container(
            decoration: BoxDecoration(
              border: focused
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: _onTap,
              child: Semantics(
                button: true,
                label: 'Book: ${book.title} by ${book.author}',
                onTap: _onTap,
                child: _buildCardContent(),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Screen Reader Support
```dart
// ✅ Semantic labels for screen readers
Widget build(BuildContext context) {
  return Semantics(
    label: 'Search for books',
    hint: 'Enter book title or author name',
    textField: true,
    child: TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search books...',
      ),
    ),
  );
}
```

## 📱 Responsive Design

### Layout Breakpoints
```dart
// ✅ Responsive layout implementation
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1200) {
          return tablet;
        } else {
          return desktop;
        }
      },
    );
  }
}

// Usage example
ResponsiveLayout(
  mobile: _buildMobileLayout(),
  tablet: _buildTabletLayout(),
  desktop: _buildDesktopLayout(),
)
```

### Adaptive Layouts
```dart
// ✅ Adaptive book grid
class BookGrid extends StatelessWidget {
  final List<Book> books;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) => BookCard(book: books[index]),
        );
      },
    );
  }
  
  int _getCrossAxisCount(double width) {
    if (width < 600) return 2;      // Mobile
    if (width < 900) return 3;      // Tablet
    if (width < 1200) return 4;     // Small desktop
    return 5;                       // Large desktop
  }
}
```

## 🎨 Animation Guidelines

### Page Transitions
```dart
// ✅ Smooth page transitions
class BookDetailsRoute extends PageRouteBuilder {
  final Book book;
  
  BookDetailsRoute({required this.book})
      : super(
          pageBuilder: (context, animation, _) => BookDetailsView(book: book),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
```

### Loading States
```dart
// ✅ Elegant loading animations
class LoadingBookCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceVariant,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🚨 Common UI/UX Issues

### Issue: Inconsistent Spacing
```dart
// ❌ Inconsistent spacing
Column(
  children: [
    Text('Title'),
    SizedBox(height: 12),  // Random spacing
    Text('Subtitle'),
    SizedBox(height: 6),   // Different spacing
    Button(),
  ],
)

// ✅ Consistent spacing system
Column(
  children: [
    Text('Title'),
    const SizedBox(height: 16),  // Use 8px multiples
    Text('Subtitle'),
    const SizedBox(height: 8),   // Consistent system
    Button(),
  ],
)
```

### Issue: Missing Test Keys
```dart
// ❌ No test identification
ElevatedButton(
  onPressed: _download,
  child: Text('Download'),
)

// ✅ With test key
ElevatedButton(
  key: Key('download-btn-${book.id}'),
  onPressed: _download,
  child: const Text('Download'),
)
```

## 📚 UI Component Checklist

### Every Interactive Widget Must Have:
- [ ] Unique test key (`key: Key('element-id')`)
- [ ] Proper semantic labels for accessibility
- [ ] Loading and error states
- [ ] Keyboard navigation support
- [ ] Consistent Material 3 styling
- [ ] Responsive behavior
- [ ] Proper focus indicators

### Every Screen Must Have:
- [ ] AppBar with consistent styling
- [ ] Loading states for async operations
- [ ] Error handling with user-friendly messages
- [ ] Empty states with helpful guidance
- [ ] Keyboard navigation between elements
- [ ] Proper back button handling
- [ ] Test keys for major UI elements

---

**Last Updated**: 2025-08-28  
**Status**: Active  
**Design System**: Material 3

*Follow these guidelines for consistent, accessible, and beautiful UI across SailorBook.*