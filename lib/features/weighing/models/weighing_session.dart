import '../../../core/enums/can_lua_enums.dart';
import 'bag_weight.dart';
import 'weighing_group.dart';

class WeighingSession {
  final String id;
  final String sessionCode;
  final String farmerName;
  final String traderName;
  final String phoneNumber;
  final RiceVariety riceVariety;
  final double pricePerKg;
  final double tarePerBagKg;
  final double depositAmount;
  final String note;
  final WeighingSessionStatus status;
  final WeighingGroupingMode groupingMode;
  final int bagsPerGroup;
  final int groupsPerBatch;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<BagWeight> bags;

  const WeighingSession({
    required this.id,
    required this.sessionCode,
    required this.farmerName,
    this.traderName = '',
    this.phoneNumber = '',
    this.riceVariety = RiceVariety.om5451,
    this.pricePerKg = 8000.0,
    this.tarePerBagKg = 0.2,
    this.depositAmount = 0.0,
    this.note = '',
    this.status = WeighingSessionStatus.draft,
    this.groupingMode = WeighingGroupingMode.groupedBatch,
    this.bagsPerGroup = 5,
    this.groupsPerBatch = 5,
    required this.createdAt,
    this.completedAt,
    this.bags = const [],
  });

  // Computed metrics
  int get totalBags => bags.length;

  double get totalGrossWeight =>
      bags.fold(0.0, (sum, bag) => sum + bag.grossWeight);

  double get totalTareWeight => totalBags * tarePerBagKg;

  double get netWeight {
    final net = totalGrossWeight - totalTareWeight;
    return net > 0 ? net : 0.0;
  }

  double get totalAmount => netWeight * pricePerKg;

  double get remainingPayable => totalAmount - depositAmount;

  double get averageBagWeight =>
      totalBags > 0 ? (totalGrossWeight / totalBags) : 0.0;

  /// Partition bags into custom groups (e.g. 5 bags per group)
  List<WeighingGroup> getGroups() {
    if (bags.isEmpty) return const [];
    final effectiveBagsPerGroup = bagsPerGroup > 0 ? bagsPerGroup : 5;
    final groupCount = (bags.length / effectiveBagsPerGroup).ceil();

    return List<WeighingGroup>.generate(groupCount, (i) {
      final start = i * effectiveBagsPerGroup;
      final end = (start + effectiveBagsPerGroup < bags.length)
          ? start + effectiveBagsPerGroup
          : bags.length;
      return WeighingGroup(
        groupIndex: i + 1,
        bags: bags.sublist(start, end),
        pricePerKg: pricePerKg,
        tarePerBagKg: tarePerBagKg,
      );
    });
  }

  /// Partition groups into batches (e.g. 5 groups per batch = 25 bags)
  List<WeighingBatch> getBatches() {
    final allGroups = getGroups();
    if (allGroups.isEmpty) return const [];

    if (groupingMode == WeighingGroupingMode.continuous || groupsPerBatch <= 0) {
      return [
        WeighingBatch(
          batchIndex: 1,
          groups: allGroups,
          pricePerKg: pricePerKg,
          tarePerBagKg: tarePerBagKg,
          targetGroupsPerBatch: allGroups.length,
        ),
      ];
    }

    final batchCount = (allGroups.length / groupsPerBatch).ceil();
    return List<WeighingBatch>.generate(batchCount, (i) {
      final start = i * groupsPerBatch;
      final end = (start + groupsPerBatch < allGroups.length)
          ? start + groupsPerBatch
          : allGroups.length;
      return WeighingBatch(
        batchIndex: i + 1,
        groups: allGroups.sublist(start, end),
        pricePerKg: pricePerKg,
        tarePerBagKg: tarePerBagKg,
        targetGroupsPerBatch: groupsPerBatch,
      );
    });
  }

  WeighingBatch? get activeBatch {
    final batches = getBatches();
    return batches.isNotEmpty ? batches.last : null;
  }

  WeighingGroup? get activeGroup {
    final groups = getGroups();
    return groups.isNotEmpty ? groups.last : null;
  }

  List<List<BagWeight>> getMatrixRows({int columns = 10}) {
    final List<List<BagWeight>> rows = [];
    for (int i = 0; i < bags.length; i += columns) {
      final end = (i + columns < bags.length) ? i + columns : bags.length;
      rows.add(bags.sublist(i, end));
    }
    return rows;
  }

  WeighingSession copyWith({
    String? id,
    String? sessionCode,
    String? farmerName,
    String? traderName,
    String? phoneNumber,
    RiceVariety? riceVariety,
    double? pricePerKg,
    double? tarePerBagKg,
    double? depositAmount,
    String? note,
    WeighingSessionStatus? status,
    WeighingGroupingMode? groupingMode,
    int? bagsPerGroup,
    int? groupsPerBatch,
    DateTime? createdAt,
    DateTime? completedAt,
    List<BagWeight>? bags,
  }) {
    return WeighingSession(
      id: id ?? this.id,
      sessionCode: sessionCode ?? this.sessionCode,
      farmerName: farmerName ?? this.farmerName,
      traderName: traderName ?? this.traderName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      riceVariety: riceVariety ?? this.riceVariety,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      tarePerBagKg: tarePerBagKg ?? this.tarePerBagKg,
      depositAmount: depositAmount ?? this.depositAmount,
      note: note ?? this.note,
      status: status ?? this.status,
      groupingMode: groupingMode ?? this.groupingMode,
      bagsPerGroup: bagsPerGroup ?? this.bagsPerGroup,
      groupsPerBatch: groupsPerBatch ?? this.groupsPerBatch,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      bags: bags ?? this.bags,
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
      'note': note,
      'status': status.name,
      'groupingMode': groupingMode.name,
      'bagsPerGroup': bagsPerGroup,
      'groupsPerBatch': groupsPerBatch,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'bags': bags.map((b) => b.toJson()).toList(),
    };
  }

  factory WeighingSession.fromJson(Map<String, dynamic> json) {
    return WeighingSession(
      id: json['id'] as String? ?? '',
      sessionCode: json['sessionCode'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? 'Chủ ruộng',
      traderName: json['traderName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      riceVariety: RiceVariety.fromString(json['riceVariety'] as String?),
      pricePerKg: (json['pricePerKg'] as num?)?.toDouble() ?? 8000.0,
      tarePerBagKg: (json['tarePerBagKg'] as num?)?.toDouble() ?? 0.2,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String? ?? '',
      status: WeighingSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => WeighingSessionStatus.draft,
      ),
      groupingMode: WeighingGroupingMode.fromString(json['groupingMode'] as String?),
      bagsPerGroup: json['bagsPerGroup'] as int? ?? 5,
      groupsPerBatch: json['groupsPerBatch'] as int? ?? 5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      bags: (json['bags'] as List<dynamic>?)
              ?.map((e) => BagWeight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
