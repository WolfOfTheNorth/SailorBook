/// Stub implementation for non-web platforms
/// Provides a no-op context object to replace dart:js functionality

class _Context {
  void callMethod(String method, List<dynamic> args) {
    // No-op implementation for non-web platforms
  }
}

final _Context context = _Context();