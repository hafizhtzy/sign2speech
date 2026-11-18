import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstraction over encrypted key-value storage so unit/widget tests can inject
/// an in-memory store while production uses [FlutterSecureStorage].
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
}

/// Production implementation backed by Android Keystore / iOS Keychain via
/// `flutter_secure_storage: ^11.2.0`.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureKeyValueStore({
    this._storage = const FlutterSecureStorage(),
  });

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}

/// Deterministic in-memory store for unit and widget tests.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _map = <String, String>{};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _map.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);
}

/// Encrypted [LocalStorage] implementation for `supabase_flutter: ^2.18.3`
/// (`FlutterAuthClientOptions.localStorage`).
class SecureSupabaseLocalStorage extends LocalStorage {
  static const String defaultSessionKey =
      'sign2speech.supabase.auth.persisted_session.v3';

  final SecureKeyValueStore _store;
  final String persistSessionKey;

  const SecureSupabaseLocalStorage({
    this._store = const FlutterSecureKeyValueStore(),
    this.persistSessionKey = defaultSessionKey,
  });

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      final val = await _store.read(persistSessionKey);
      return val != null && val.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _store.read(persistSessionKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _store.delete(persistSessionKey);
    } catch (_) {}
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _store.write(persistSessionKey, persistSessionString);
    } catch (_) {}
  }
}

/// Encrypted [GotrueAsyncStorage] implementation for PKCE code verifier
/// (`FlutterAuthClientOptions.pkceAsyncStorage`) in `supabase_flutter: ^2.18.3`.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  final SecureKeyValueStore _store;

  const SecureGotrueAsyncStorage({
    this._store = const FlutterSecureKeyValueStore(),
  });

  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await _store.read(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await _store.delete(key);
    } catch (_) {}
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    try {
      await _store.write(key, value);
    } catch (_) {}
  }
}
