import 'package:flutter/foundation.dart';

/// Feature flags cho app, hỗ trợ điều khiển behavior theo environment.
///
/// Sử dụng `--dart-define=SEED_DB=true` khi chạy flutter để bật seed.
/// Mặc định chỉ cho phép seed ở debug mode.
abstract class AppFlags {
  /// Có cho phép seed database hay không (từ dart-define).
  static const bool seedDb = bool.fromEnvironment(
    'SEED_DB',
    defaultValue: false,
  );

  /// Seed chỉ chạy khi ở debug mode hoặc khi flag SEED_DB=true.
  static bool get canSeed => kDebugMode || seedDb;
}
