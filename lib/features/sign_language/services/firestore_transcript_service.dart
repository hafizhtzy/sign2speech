import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_result.dart';
import '../models/sign_token.dart';

/// Production-ready Firestore Service for storing and syncing sign recognition transcripts.
/// Reduces local storage bloat by archiving recognition transcripts to Cloud Firestore.
class FirestoreTranscriptService {
  final FirebaseFirestore? _customFirestore;

  FirestoreTranscriptService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _transcriptsCollection =>
      _firestore?.collection('sign_transcripts');

  /// Archives a sequence of sign recognition tokens to Cloud Firestore.
  Future<FirestoreResult<String>> archiveSessionTranscript({
    required String sessionId,
    required List<SignToken> tokens,
    String languageType = 'BISINDO',
    String? sessionNotes,
  }) async {
    final col = _transcriptsCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final docId = sessionId.isNotEmpty
          ? sessionId
          : 'TRX-${DateTime.now().millisecondsSinceEpoch}';

      final tokenMaps = tokens.map((t) => t.toJson()).toList();
      final sentence = tokens.map((t) => t.value).join(' ');

      final payload = {
        'sessionId': docId,
        'tokens': tokenMaps,
        'fullSentence': sentence,
        'tokenCount': tokens.length,
        'languageType': languageType,
        'sessionNotes': sessionNotes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await col.doc(docId).set(payload, SetOptions(merge: true));
      return FirestoreSuccess(docId);
    } catch (e, stack) {
      debugPrint('FirestoreTranscriptService archive error: $e\n$stack');
      return FirestoreFailure('Failed to archive transcript to cloud', e);
    }
  }

  /// Fetches recent transcript sessions from Cloud Firestore
  Future<FirestoreResult<List<Map<String, dynamic>>>> fetchRecentTranscripts({
    int limit = 20,
  }) async {
    final col = _transcriptsCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final querySnapshot = await col
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final list = querySnapshot.docs.map((d) => d.data()).toList();
      return FirestoreSuccess(list);
    } catch (e) {
      debugPrint('FirestoreTranscriptService fetch error: $e');
      return FirestoreFailure('Failed to fetch transcripts', e);
    }
  }
}
