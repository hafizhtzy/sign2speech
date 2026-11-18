import 'package:flutter/foundation.dart';

@immutable
class AuditLogEntry {
  final String id;
  final String? actorId;
  final String actorRole;
  final String actorName;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final Map<String, dynamic> metadata;
  final String status;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    this.actorId,
    required this.actorRole,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.beforeData,
    this.afterData,
    this.metadata = const {},
    this.status = 'success',
    required this.createdAt,
  });

  factory AuditLogEntry.fromPostgresMap(Map<String, dynamic> map) {
    final rawBefore = map['before_data'];
    final rawAfter = map['after_data'];
    final rawMeta = map['metadata'];

    return AuditLogEntry(
      id: (map['id'] ?? '').toString(),
      actorId: map['actor_id']?.toString(),
      actorRole: (map['actor_role'] ?? 'system').toString(),
      actorName: (map['actor_name'] ?? 'System').toString(),
      action: (map['action'] ?? '').toString(),
      entityType: (map['entity_type'] ?? '').toString(),
      entityId: (map['entity_id'] ?? '').toString(),
      beforeData: rawBefore is Map
          ? Map<String, dynamic>.from(rawBefore)
          : null,
      afterData: rawAfter is Map ? Map<String, dynamic>.from(rawAfter) : null,
      metadata: rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : const {},
      status: (map['status'] ?? 'success').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString())?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}
