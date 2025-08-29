import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for adding test identifiers to Flutter widgets for E2E testing
class TestHelpers {
  /// Creates a Semantics widget with a test identifier for web testing.
  /// This generates `data-testid` attributes in the DOM for Playwright.
  ///
  /// Usage:
  /// ```dart
  /// TestHelpers.withTestId(
  ///   'my-button',
  ///   ElevatedButton(
  ///     onPressed: () {},
  ///     child: Text('Click me'),
  ///   ),
  /// )
  /// ```
  static Widget withTestId(
    String testId,
    Widget child, {
    String? label,
    bool button = false,
    bool textField = false,
  }) {
    // Only add semantics for web builds or debug mode
    if (kIsWeb || kDebugMode) {
      return Semantics(
        identifier: testId,
        label: label ?? testId.replaceAll('-', ' ').toUpperCase(),
        button: button,
        textField: textField,
        enabled: true,
        child: child,
      );
    }
    
    // In release builds for mobile, just return the child
    return child;
  }

  /// Creates a test identifier specifically for buttons
  static Widget button(String testId, Widget child, {String? label}) {
    return withTestId(
      testId,
      child,
      label: label,
      button: true,
    );
  }

  /// Creates a test identifier specifically for text fields
  static Widget textField(String testId, Widget child, {String? label}) {
    return withTestId(
      testId,
      child,
      label: label,
      textField: true,
    );
  }

  /// Creates a test identifier for containers/views
  static Widget container(String testId, Widget child, {String? label}) {
    return withTestId(
      testId,
      child,
      label: label,
    );
  }

  /// Creates a test identifier for list items
  static Widget listItem(String testId, Widget child, {String? label}) {
    return withTestId(
      testId,
      child,
      label: label,
    );
  }
}

/// Extension on Widget to add test identifiers more fluently
extension TestIdExtension on Widget {
  /// Wraps this widget with a test identifier
  Widget withTestId(String testId, {String? label}) {
    return TestHelpers.withTestId(testId, this, label: label);
  }

  /// Wraps this widget as a testable button
  Widget asTestButton(String testId, {String? label}) {
    return TestHelpers.button(testId, this, label: label);
  }

  /// Wraps this widget as a testable text field
  Widget asTestTextField(String testId, {String? label}) {
    return TestHelpers.textField(testId, this, label: label);
  }

  /// Wraps this widget as a testable container
  Widget asTestContainer(String testId, {String? label}) {
    return TestHelpers.container(testId, this, label: label);
  }
}