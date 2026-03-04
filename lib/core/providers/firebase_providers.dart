import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized Firebase DI providers.
///
/// Tất cả Firebase instances đi qua Riverpod providers để:
/// - Dễ dàng mock/test
/// - Thống nhất DI pattern toàn app
/// - Có thể override cho từng environment

/// Firebase Auth provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((_) {
  return FirebaseAuth.instance;
});

/// Cloud Firestore provider.
final firestoreProvider = Provider<FirebaseFirestore>((_) {
  return FirebaseFirestore.instance;
});

/// Firebase Storage provider.
final firebaseStorageProvider = Provider<FirebaseStorage>((_) {
  return FirebaseStorage.instance;
});
