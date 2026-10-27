import '../../../core/enums/can_lua_enums.dart';
import 'weighing_session.dart';

/// Lightweight summary metadata of a weighing session used for the index list.
/// Stored separately from heavy bag arrays to allow loading 10,000+ sessions in milliseconds.
class SessionIndexItem {
  final String id;
  final String sessionCode;
  final String farmerName;
  final String traderName;
  final String phoneNumber;
  final RiceVariety riceVariety;
  final double pricePerKg;
  final double tarePerBagKg;
  final double depositAmount;
  final WeighingSessionStatus status;
  final WeighingGroupingMode groupingMode;
  final int bagsPerGroup;
  final int groupsPerBatch;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int totalBags;
  final double totalGrossWeight;
  final double netWeight;
  final double totalAmount;
  final double remainingPayable;

  const SessionIndexItem({
    required this.id,
    required this.sessionCode,
    required this.farmerName,
    this.traderName = '',
    this.phoneNumber = '',
    this.riceVariety = RiceVariety.om5451,
    this.pricePerKg = 8000.0,
    this.tarePerBagKg = 0.2,
    this.depositAmount = 0.0,
    this.status = WeighingSessionStatus.draft,
    this.groupingMode = WeighingGroupingMode.groupedBatch,
    this.bagsPerGroup = 5,
    this.groupsPerBatch = 5,
    required this.createdAt,
    this.completedAt,
    this.totalBags = 0,
    this.totalGrossWeight = 0.0,
    this.netWeight = 0.0,
    this.totalAmount = 0.0,
    this.remainingPayable = 0.0,
  });

  factory SessionIndexItem.fromSession(WeighingSession session) {
    return SessionIndexItem(
      id: session.id,
      sessionCode: session.sessionCode,
      farmerName: session.farmerName,
      traderName: session.traderName,
      phoneNumber: session.phoneNumber,
      riceVariety: session.riceVariety,
      pricePerKg: session.pricePerKg,
      tarePerBagKg: session.tarePerBagKg,
      depositAmount: session.depositAmount,
      status: session.status,
      groupingMode: session.groupingMode,
      bagsPerGroup: session.bagsPerGroup,
      groupsPerBatch: session.groupsPerBatch,
      createdAt: session.createdAt,
      completedAt: session.completedAt,
      totalBags: session.totalBags,
      totalGrossWeight: session.totalGrossWeight,
      netWeight: session.netWeight,
      totalAmount: session.totalAmount,
      remainingPayable: session.remainingPayable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionCode': sessionCode,
      'farmerName': farmerName,
      'traderName': traderName,
      'phoneNumber': phoneNumber,
      'riceVariety': riceVariety.name,
      'pricePerKg': pricePerKg,
      'tarePerBagKg': tarePerBagKg,
      'depositAmount': depositAmount,
      'status': status.name,
      'groupingMode': groupingMode.name,
      'bagsPerGroup': bagsPerGroup,
      'groupsPerBatch': groupsPerBatch,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalBags': totalBags,
      'totalGrossWeight': totalGrossWeight,
      'netWeight': netWeight,
      'totalAmount': totalAmount,
      'remainingPayable': remainingPayable,
    };
  }

  factory SessionIndexItem.fromJson(Map<String, dynamic> json) {
    return SessionIndexItem(
      id: json['id'] as String? ?? '',
      sessionCode: json['sessionCode'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? 'Chủ ruộng',
      traderName: json['traderName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      riceVariety: RiceVariety.fromString(json['riceVariety'] as String?),
      pricePerKg: (json['pricePerKg'] as num?)?.toDouble() ?? 8000.0,
      tarePerBagKg: (json['tarePerBagKg'] as num?)?.toDouble() ?? 0.2,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      status: WeighingSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => WeighingSessionStatus.draft,
      ),
      groupingMode:
          WeighingGroupingMode.fromString(json['groupingMode'] as String?),
      bagsPerGroup: json['bagsPerGroup'] as int? ?? 5,
      groupsPerBatch: json['groupsPerBatch'] as int? ?? 5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      totalBags: (json['totalBags'] as num?)?.toInt() ?? 0,
      totalGrossWeight: (json['totalGrossWeight'] as num?)?.toDouble() ?? 0.0,
      netWeight: (json['netWeight'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingPayable: (json['remainingPayable'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
