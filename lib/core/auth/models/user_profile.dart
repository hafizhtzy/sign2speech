import 'package:flutter/foundation.dart';

import 'app_user_role.dart';

/// Immutable domain model representing an authenticated user's profile and
/// server-authoritative role in `public.profiles`.
@immutable
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final AppUserRole role;
  final AccountStatus status;
  final String communicationMode; // 'deaf' or 'hearing'
  final String preferredSignSystem; // 'BISINDO' or 'SIBI'
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.status,
    this.communicationMode = 'deaf',
    this.preferredSignSystem = 'BISINDO',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == AccountStatus.active;

  /// Parses an authoritative row from `public.profiles`.
  /// Explicitly reads top-level `role` and `status` columns and never trusts
  /// client-mutable `user_metadata`.
  factory UserProfile.fromPostgresMap(Map<String, dynamic> map) {
    final now = DateTime.now().toUtc();
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? map['fullName'] ?? '').toString(),
      phone: map['phone']?.toString(),
      role: AppUserRole.fromString(map['role']?.toString()),
      status: AccountStatus.fromString(map['status']?.toString()),
      communicationMode:
          (map['communication_mode'] ?? map['communicationMode'] ?? 'deaf')
              .toString(),
      preferredSignSystem:
          (map['preferred_sign_system'] ??
                  map['preferredSignSystem'] ??
                  'BISINDO')
              .toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toUtc() ??
          now,
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '')?.toUtc() ??
          now,
    );
  }

  /// Serializes ONLY user-editable profile fields.
  /// Never includes `id`, `email`, `role`, or `status` so self-updates cannot
  /// attempt privilege escalation or account status tampering.
  Map<String, dynamic> toSelfEditableMap() {
    return <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'communication_mode': communicationMode,
      'preferred_sign_system': preferredSignSystem,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    AppUserRole? role,
    AccountStatus? status,
    String? communicationMode,
    String? preferredSignSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      communicationMode: communicationMode ?? this.communicationMode,
      preferredSignSystem: preferredSignSystem ?? this.preferredSignSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
