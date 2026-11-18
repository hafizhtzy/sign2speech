import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_routes.dart';
import '../../supabase/supabase_result.dart';
import '../models/app_user_role.dart';
import '../models/user_profile.dart';
import '../services/supabase_auth_service.dart';

/// Dart 3 sealed class representing authentication & authorization state.
sealed class AuthSessionState {
  const AuthSessionState();
}

final class AuthInitial extends AuthSessionState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AuthSessionState {
  const AuthUnauthenticated();
}

final class AuthAuthenticating extends AuthSessionState {
  const AuthAuthenticating();
}

final class AuthAuthenticated extends AuthSessionState {
  final UserProfile profile;
  const AuthAuthenticated(this.profile);
}

final class AuthDisabled extends AuthSessionState {
  final String reason;
  const AuthDisabled(this.reason);
}

/// Central GetX controller managing the three-role authorization lifecycle
/// (`CUSTOMER`, `CASHIER`, `ADMIN`) and instant account revocation.
class AuthController extends GetxController {
  final SupabaseAuthService _authService;

  final Rx<AuthSessionState> sessionState =
      Rx<AuthSessionState>(const AuthUnauthenticated());
  final Rxn<UserProfile> currentProfile = Rxn<UserProfile>();
  final RxString errorMessage = ''.obs;
  final RxBool isSubmitting = false.obs;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  AuthController({
    SupabaseAuthService? authService,
    UserProfile? initialProfileForTest,
  }) : _authService = authService ?? SupabaseAuthService() {
    if (initialProfileForTest != null) {
      applyProfileUpdate(initialProfileForTest);
    }
  }

  bool get isAuthenticated =>
      currentProfile.value != null && currentProfile.value!.isActive;

  AppUserRole? get currentRole =>
      isAuthenticated ? currentProfile.value?.role : null;

  bool get isCustomer => currentRole == AppUserRole.customer;
  bool get isCashier => currentRole == AppUserRole.cashier;
  bool get isAdmin => currentRole == AppUserRole.admin;

  /// Returns the home route corresponding to the user's authoritative role.
  String get homeRouteForCurrentRole => switch (currentRole) {
    AppUserRole.admin => AppRoutes.adminDashboard,
    AppUserRole.cashier => AppRoutes.cafeCashierCounter,
    AppUserRole.customer => AppRoutes.mainShell,
    null => AppRoutes.login,
  };

  @override
  void onInit() {
    super.onInit();
    if (currentProfile.value == null) {
      _bootstrapSession();
    }
    _authSub = _authService.onAuthStateChange.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedOut) {
        _clearAuthenticatedState();
      } else if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        final user = authState.session?.user;
        if (user != null) {
          _loadAndWatchProfile(user.id, fallbackUser: user);
        }
      }
    });
  }

  Future<void> _bootstrapSession() async {
    final user = _authService.currentAuthUser;
    if (user == null) {
      sessionState.value = const AuthUnauthenticated();
      return;
    }
    await _loadAndWatchProfile(user.id, fallbackUser: user);
  }

  Future<void> _loadAndWatchProfile(String userId, {User? fallbackUser}) async {
    final result = await _authService.fetchProfileByUserId(
      userId,
      fallbackUser: fallbackUser,
    );
    switch (result) {
      case SupabaseSuccess(:final data):
        applyProfileUpdate(data);
        _subscribeProfileChanges(userId);
      case SupabaseFailure(:final errorMessage):
        this.errorMessage.value = errorMessage;
        _clearAuthenticatedState();
    }
  }

  void _subscribeProfileChanges(String userId) {
    _profileSub?.cancel();
    _profileSub = _authService.streamOwnProfile(userId).listen(
      (profile) {
        if (profile != null) {
          applyProfileUpdate(profile);
        }
      },
      onError: (_) {},
    );
  }

  /// Applies a profile update and enforces instant revocation if status is disabled.
  void applyProfileUpdate(UserProfile profile) {
    if (!profile.isActive) {
      currentProfile.value = null;
      sessionState.value = const AuthDisabled(
        'Akun Anda telah dinonaktifkan oleh Admin.',
      );
      errorMessage.value = 'Akun Anda telah dinonaktifkan oleh Admin.';
      unawaited(_authService.signOut());
      return;
    }
    currentProfile.value = profile;
    sessionState.value = AuthAuthenticated(profile);
    errorMessage.value = '';
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    errorMessage.value = '';
    sessionState.value = const AuthAuthenticating();
    try {
      final result = await _authService.signInWithPassword(
        email: email,
        password: password,
      );
      return switch (result) {
        SupabaseSuccess(:final data) => () {
          applyProfileUpdate(data);
          _subscribeProfileChanges(data.id);
          return isAuthenticated;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          sessionState.value = const AuthUnauthenticated();
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String communicationMode = 'deaf',
    String preferredSignSystem = 'BISINDO',
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    errorMessage.value = '';
    sessionState.value = const AuthAuthenticating();
    try {
      final result = await _authService.registerCustomer(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        communicationMode: communicationMode,
        preferredSignSystem: preferredSignSystem,
      );
      return switch (result) {
        SupabaseSuccess(:final data) => () {
          applyProfileUpdate(data);
          _subscribeProfileChanges(data.id);
          return isAuthenticated;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          sessionState.value = const AuthUnauthenticated();
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateOwnProfile({
    required String fullName,
    String? phone,
    String? communicationMode,
    String? preferredSignSystem,
  }) async {
    final current = currentProfile.value;
    if (current == null || isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final updated = current.copyWith(
        fullName: fullName,
        phone: phone,
        communicationMode: communicationMode,
        preferredSignSystem: preferredSignSystem,
      );
      final res = await _authService.updateOwnProfile(updated);
      return switch (res) {
        SupabaseSuccess(:final data) => () {
          applyProfileUpdate(data);
          return true;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> signOut() async {
    await _profileSub?.cancel();
    _profileSub = null;
    await _authService.signOut();
    _clearAuthenticatedState();
  }

  void _clearAuthenticatedState() {
    currentProfile.value = null;
    sessionState.value = const AuthUnauthenticated();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.onClose();
  }
}
