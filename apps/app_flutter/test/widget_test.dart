// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdreader/main.dart';

void main() {
  testWidgets('PDReaderApp loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PDReaderApp(),
      ),
    );

    // Wait for the app to build
    await tester.pumpAndSettle();

    // Verify that the app loads with the expected title
    expect(find.text('Public-Domain Reader'), findsOneWidget);
    
    // Verify that the library and search tabs are present
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('Tab navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PDReaderApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the search tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Verify we can see search-related UI
    expect(find.text('Search for books...'), findsOneWidget);
  });
}
