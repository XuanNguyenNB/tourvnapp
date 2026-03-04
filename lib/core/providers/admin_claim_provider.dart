import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';

/// Cache admin claim để tránh gọi getIdTokenResult() mỗi lần navigate.
///
/// Provider này check custom claim 'admin' một lần rồi cache kết quả.
/// Khi cần refresh (ví dụ sau login/logout), invalidate provider:
/// ```dart
/// ref.invalidate(adminClaimProvider);
/// ```
final adminClaimProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;

  if (user == null || user.isAnonymous) return false;

  try {
    final token = await user.getIdTokenResult();
    return token.claims?['admin'] == true;
  } catch (e) {
    return false;
  }
});
