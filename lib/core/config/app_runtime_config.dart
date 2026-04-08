import 'package:flutter/foundation.dart';

/// Runtime configuration injected at build time with `--dart-define`.
///
/// Example:
/// `flutter run --dart-define=AI_BACKEND_BASE_URL=https://your-ai-host.example.com`
abstract final class AppRuntimeConfig {
  static const String _aiBackendBaseUrl = String.fromEnvironment(
    'AI_BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String? get aiBackendBaseUrl {
    final trimmed = _aiBackendBaseUrl.trim();
    if (trimmed.isEmpty) {
      if (kDebugMode) return 'http://127.0.0.1:8787';
      return null;
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static bool get hasAiBackend => aiBackendBaseUrl != null;
}
