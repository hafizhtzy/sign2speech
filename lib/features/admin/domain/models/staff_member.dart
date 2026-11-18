import 'package:flutter/foundation.dart';

import '../../../../core/auth/models/app_user_role.dart';

@immutable
class StaffMember {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final AppUserRole role;
  final AccountStatus status;
  final DateTime? emailConfirmedAt;
  final DateTime? lastSignInAt;
  final int ordersProcessed;
  final int totalHandledSales;
  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.role = AppUserRole.cashier,
    this.status = AccountStatus.active,
    this.emailConfirmedAt,
    this.lastSignInAt,
    this.ordersProcessed = 0,
    this.totalHandledSales = 0,
    required this.createdAt,
  });

  bool get isActive => status == AccountStatus.active;
  bool get isEmailVerified => emailConfirmedAt != null;

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? map['fullName'] ?? '').toString(),
      phone: map['phone']?.toString(),
      role: AppUserRole.fromString(map['role']?.toString()),
      status: AccountStatus.fromString(map['status']?.toString()),
      emailConfirmedAt: DateTime.tryParse(
        (map['email_confirmed_at'] ?? '').toString(),
      )?.toUtc(),
      lastSignInAt: DateTime.tryParse(
        (map['last_sign_in_at'] ?? '').toString(),
      )?.toUtc(),
      ordersProcessed:
          ((map['orders_processed'] ?? map['ordersProcessed'] ?? 0) as num)
              .toInt(),
      totalHandledSales:
          ((map['total_handled_sales'] ?? map['totalHandledSales'] ?? 0) as num)
              .toInt(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString())?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}
