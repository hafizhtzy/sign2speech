import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_result.dart';

/// Production-ready Firestore Service for syncing user preferences & accessibility settings.
/// Adheres to Clean Architecture and Dart 3 sealed class modeling.
class FirestoreSettingsService {
  final FirebaseFirestore? _customFirestore;

  FirestoreSettingsService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _settingsCollection =>
      _firestore?.collection('user_settings');

  /// Saves user settings to Cloud Firestore
  Future<FirestoreResult<void>> saveSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    final col = _settingsCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final payload = Map<String, dynamic>.from(settings);
      payload['userId'] = userId;
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await col.doc(userId).set(payload, SetOptions(merge: true));
      return const FirestoreSuccess(null);
    } catch (e, stack) {
      debugPrint('FirestoreSettingsService saveSettings error: $e\n$stack');
      return FirestoreFailure('Failed to save settings to cloud', e);
    }
  }

  /// Fetches user settings from Cloud Firestore
  Future<FirestoreResult<Map<String, dynamic>?>> fetchSettings(
    String userId,
  ) async {
    final col = _settingsCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final doc = await col.doc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return const FirestoreSuccess(null);
      }
      return FirestoreSuccess(doc.data());
    } catch (e) {
      debugPrint('FirestoreSettingsService fetchSettings error: $e');
      return FirestoreFailure('Failed to fetch settings from cloud', e);
    }
  }

  /// Realtime stream of user settings
  Stream<Map<String, dynamic>?> streamSettings(String userId) {
    final col = _settingsCollection;
    if (col == null) {
      return Stream.value(null);
    }

    return col.doc(userId).snapshots().map((doc) => doc.data());
  }
}
