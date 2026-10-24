import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/history_item.dart';

import '../../../core/firebase/firestore_result.dart';
export '../../../core/firebase/firestore_result.dart';

/// Production-ready Firestore Service adhering to Clean Architecture & Dart 3
class FirestoreHistoryService {
  final FirebaseFirestore? _customFirestore;

  FirestoreHistoryService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _historyCollection =>
      _firestore?.collection('translations_history');

  CollectionReference<Map<String, dynamic>>? get _testCollection =>
      _firestore?.collection('test_connection');

  /// Verifies Firestore connectivity by reading the MVP initialization test document
  Future<FirestoreResult<Map<String, dynamic>>> testConnection() async {
    final col = _testCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }
    try {
      final docSnapshot = await col.doc('mvp_init_test').get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return FirestoreSuccess(docSnapshot.data()!);
      } else {
        // Create initial probe document if not present
        final probeData = {
          'message': 'Probe active from Flutter client',
          'timestamp': FieldValue.serverTimestamp(),
          'client': 'Sign2Speech Mobile MVP',
        };
        await col.doc('flutter_client_probe').set(probeData);
        return FirestoreSuccess(probeData);
      }
    } catch (e, stack) {
      debugPrint('Firestore testConnection error: $e\n$stack');
      return FirestoreFailure('Failed to connect to Cloud Firestore', e);
    }
  }

  /// Saves a single history item to Cloud Firestore
  Future<FirestoreResult<String>> saveHistory(HistoryItem item) async {
    final col = _historyCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }
    try {
      final payload = item.toMap();
      payload['createdAt'] = FieldValue.serverTimestamp();
      await col.doc(item.id).set(payload);
      return FirestoreSuccess(item.id);
    } catch (e) {
      debugPrint('Firestore saveHistory error: $e');
      return FirestoreFailure('Failed to save history to cloud', e);
    }
  }

  /// Fetches translation history items from Cloud Firestore
  Future<FirestoreResult<List<HistoryItem>>> fetchHistory({
    int limit = 50,
  }) async {
    final col = _historyCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }
    try {
      final querySnapshot = await col
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HistoryItem.fromMap(data);
      }).toList();

      return FirestoreSuccess(items);
    } catch (e) {
      debugPrint('Firestore fetchHistory error: $e');
      return FirestoreFailure('Failed to fetch history from cloud', e);
    }
  }

  /// Realtime Stream of translation history
  Stream<List<HistoryItem>> watchHistory({int limit = 30}) {
    final col = _historyCollection;
    if (col == null) {
      return Stream.value(<HistoryItem>[]);
    }
    return col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HistoryItem.fromMap(doc.data())).toList();
    });
  }

  /// Deletes a history item by ID from Cloud Firestore
  Future<FirestoreResult<void>> deleteHistory(String id) async {
    final col = _historyCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }
    try {
      await col.doc(id).delete();
      return const FirestoreSuccess(null);
    } catch (e) {
      return FirestoreFailure('Failed to delete history item: $id', e);
    }
  }
}
