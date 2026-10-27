class BagWeight {
  final int index;
  final double grossWeight;
  final DateTime recordedAt;

  const BagWeight({
    required this.index,
    required this.grossWeight,
    required this.recordedAt,
  });

  BagWeight copyWith({
    int? index,
    double? grossWeight,
    DateTime? recordedAt,
  }) {
    return BagWeight(
      index: index ?? this.index,
      grossWeight: grossWeight ?? this.grossWeight,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'grossWeight': grossWeight,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory BagWeight.fromJson(Map<String, dynamic> json) {
    return BagWeight(
      index: json['index'] as int? ?? 1,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
    );
  }
}
