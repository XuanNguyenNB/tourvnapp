import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider to check if the current user has Admin privileges
/// Evaluates true if user exists and has the "admin: true" custom claim
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return false;
  }

  try {
    // Force refresh the token to get the latest claims
    final idTokenResult = await user.getIdTokenResult(true);
    
    // Check if the "admin" claim exists and is true
    final claims = idTokenResult.claims;
    if (claims != null && claims['admin'] == true) {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
});
