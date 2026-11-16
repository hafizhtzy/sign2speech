import 'order_enums.dart';

/// Model untuk tabel Supabase: `counter_sessions` (`counter_id`)
/// HANYA berisi data final (bukan raw MediaPipe frames / tensor / audio).
class CafeCounterSession {
  final String counterId; // e.g. 'KAFE-01'
  final String currentOrderId;
  final CafeOrderStage stage;
  final CounterDeviceMode deviceMode;
  final String cashierTabletId;
  final String customerTabletId; // kosong jika singleTabletSwitch
  final DateTime updatedAt;

  const CafeCounterSession({
    required this.counterId,
    this.currentOrderId = '',
    this.stage = CafeOrderStage.idle,
    this.deviceMode = CounterDeviceMode.singleTabletSwitch,
    this.cashierTabletId = '',
    this.customerTabletId = '',
    required this.updatedAt,
  });

  bool get isDualTablet => deviceMode == CounterDeviceMode.dualTabletLocked;

  bool get isPaired =>
      isDualTablet && cashierTabletId.isNotEmpty && customerTabletId.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'counterId': counterId,
    'currentOrderId': currentOrderId,
    'stage': stage.name,
    'deviceMode': deviceMode.name,
    'cashierTabletId': cashierTabletId,
    'customerTabletId': customerTabletId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CafeCounterSession.fromMap(Map<String, dynamic> map) {
    final rawMode = (map['deviceMode'] ?? map['device_mode']) as String?;
    final rawUpdatedAt = map['updatedAt'] ?? map['updated_at'];
    CounterDeviceMode parsedMode;
    if (rawMode == 'dualTablet') {
      parsedMode = CounterDeviceMode.dualTabletLocked;
    } else if (rawMode == 'singleTablet') {
      parsedMode = CounterDeviceMode.singleTabletSwitch;
    } else {
      parsedMode = CounterDeviceMode.values.firstWhere(
        (e) => e.name == rawMode,
        orElse: () => CounterDeviceMode.singleTabletSwitch,
      );
    }

    return CafeCounterSession(
      counterId:
          (map['counterId'] ?? map['counter_id']) as String? ?? 'KAFE-01',
      currentOrderId:
          (map['currentOrderId'] ?? map['current_order_id']) as String? ?? '',
      stage: CafeOrderStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => CafeOrderStage.idle,
      ),
      deviceMode: parsedMode,
      cashierTabletId:
          (map['cashierTabletId'] ?? map['cashier_tablet_id']) as String? ?? '',
      customerTabletId:
          (map['customerTabletId'] ?? map['customer_tablet_id']) as String? ??
          '',
      updatedAt: rawUpdatedAt is String
          ? DateTime.tryParse(rawUpdatedAt) ?? DateTime.now()
          : rawUpdatedAt is DateTime
          ? rawUpdatedAt
          : DateTime.now(),
    );
  }

  CafeCounterSession copyWith({
    String? counterId,
    String? currentOrderId,
    CafeOrderStage? stage,
    CounterDeviceMode? deviceMode,
    String? cashierTabletId,
    String? customerTabletId,
    DateTime? updatedAt,
  }) => CafeCounterSession(
    counterId: counterId ?? this.counterId,
    currentOrderId: currentOrderId ?? this.currentOrderId,
    stage: stage ?? this.stage,
    deviceMode: deviceMode ?? this.deviceMode,
    cashierTabletId: cashierTabletId ?? this.cashierTabletId,
    customerTabletId: customerTabletId ?? this.customerTabletId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
