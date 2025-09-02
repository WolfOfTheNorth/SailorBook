import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html show document;
import 'dart:js' as js;

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
    // For web builds, create both Semantics and DOM attributes
    if (kIsWeb) {
      return _WebTestIdWrapper(
        testId: testId,
        label: label,
        child: Semantics(
          identifier: testId,
          label: label ?? testId.replaceAll('-', ' ').toUpperCase(),
          button: button,
          textField: textField,
          enabled: true,
          child: child,
        ),
      );
    } else if (kDebugMode) {
      // For mobile debug, use standard Semantics
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

/// Web-specific widget that injects data-testid attributes into DOM
class _WebTestIdWrapper extends StatefulWidget {
  final String testId;
  final String? label;
  final Widget child;
  
  const _WebTestIdWrapper({
    required this.testId,
    this.label,
    required this.child,
  });
  
  @override
  State<_WebTestIdWrapper> createState() => _WebTestIdWrapperState();
}

class _WebTestIdWrapperState extends State<_WebTestIdWrapper> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Schedule DOM injection after widget is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _injectTestIdIntoDOM();
      });
    }
  }
  
  void _injectTestIdIntoDOM() {
    try {
      // Find Flutter's glass pane and inject test attributes
      js.context.callMethod('eval', [
        '''
        (function() {
          // Create a mapping for test IDs if it doesn't exist
          if (!window.flutterTestIds) {
            window.flutterTestIds = {};
          }
          window.flutterTestIds["${widget.testId}"] = {
            label: "${widget.label ?? widget.testId}",
            timestamp: Date.now()
          };
          
          // Add data-testid attribute to glass pane for this test ID
          const glassPane = document.querySelector('flt-glass-pane');
          if (glassPane) {
            glassPane.setAttribute('data-testid-${widget.testId}', 'true');
          }
        })();
        '''
      ]);
    } catch (e) {
      // Silently fail - testing functionality shouldn't break app
      debugPrint('Test ID injection failed: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
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