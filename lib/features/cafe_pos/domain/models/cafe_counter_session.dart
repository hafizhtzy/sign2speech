import 'order_enums.dart';

/// Model untuk dokumen Firestore: `counter_sessions/{counterId}`
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

  Map<String, dynamic> toMap() => {
        'counterId': counterId,
        'currentOrderId': currentOrderId,
        'stage': stage.name,
        'deviceMode': deviceMode.name,
        'cashierTabletId': cashierTabletId,
        'customerTabletId': customerTabletId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CafeCounterSession.fromMap(Map<String, dynamic> map) =>
      CafeCounterSession(
        counterId: map['counterId'] as String? ?? 'KAFE-01',
        currentOrderId: map['currentOrderId'] as String? ?? '',
        stage: CafeOrderStage.values.firstWhere(
          (e) => e.name == map['stage'],
          orElse: () => CafeOrderStage.idle,
        ),
        deviceMode: CounterDeviceMode.values.firstWhere(
          (e) => e.name == map['deviceMode'],
          orElse: () => CounterDeviceMode.singleTabletSwitch,
        ),
        cashierTabletId: map['cashierTabletId'] as String? ?? '',
        customerTabletId: map['customerTabletId'] as String? ?? '',
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  CafeCounterSession copyWith({
    String? counterId,
    String? currentOrderId,
    CafeOrderStage? stage,
    CounterDeviceMode? deviceMode,
    String? cashierTabletId,
    String? customerTabletId,
    DateTime? updatedAt,
  }) =>
      CafeCounterSession(
        counterId: counterId ?? this.counterId,
        currentOrderId: currentOrderId ?? this.currentOrderId,
        stage: stage ?? this.stage,
        deviceMode: deviceMode ?? this.deviceMode,
        cashierTabletId: cashierTabletId ?? this.cashierTabletId,
        customerTabletId: customerTabletId ?? this.customerTabletId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
