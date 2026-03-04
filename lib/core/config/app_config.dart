/// Centralized app configuration.
///
/// API keys are injected at build time via `--dart-define`.
/// Example:
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// ```
class AppConfig {
  AppConfig._();

  /// Gemini API key – injected via `--dart-define=GEMINI_API_KEY=...`
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
