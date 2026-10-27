import 'bag_weight.dart';

class WeighingGroup {
  final int groupIndex;
  final List<BagWeight> bags;
  final double pricePerKg;
  final double tarePerBagKg;

  const WeighingGroup({
    required this.groupIndex,
    required this.bags,
    required this.pricePerKg,
    required this.tarePerBagKg,
  });

  int get totalBags => bags.length;

  double get grossWeight =>
      bags.fold(0.0, (sum, b) => sum + b.grossWeight);

  double get tareWeight => totalBags * tarePerBagKg;

  double get netWeight {
    final net = grossWeight - tareWeight;
    return net > 0 ? net : 0.0;
  }

  double get amount => netWeight * pricePerKg;
}

class WeighingBatch {
  final int batchIndex;
  final List<WeighingGroup> groups;
  final double pricePerKg;
  final double tarePerBagKg;
  final int targetGroupsPerBatch;

  const WeighingBatch({
    required this.batchIndex,
    required this.groups,
    required this.pricePerKg,
    required this.tarePerBagKg,
    this.targetGroupsPerBatch = 5,
  });

  int get totalBags =>
      groups.fold(0, (sum, g) => sum + g.totalBags);

  double get grossWeight =>
      groups.fold(0.0, (sum, g) => sum + g.grossWeight);

  double get tareWeight =>
      groups.fold(0.0, (sum, g) => sum + g.tareWeight);

  double get netWeight =>
      groups.fold(0.0, (sum, g) => sum + g.netWeight);

  double get amount =>
      groups.fold(0.0, (sum, g) => sum + g.amount);

  bool get isFull =>
      targetGroupsPerBatch > 0 && groups.length >= targetGroupsPerBatch;
}
