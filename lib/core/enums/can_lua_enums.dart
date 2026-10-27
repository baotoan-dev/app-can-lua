enum WeighingSessionStatus {
  draft,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case WeighingSessionStatus.draft:
        return 'Đang cân';
      case WeighingSessionStatus.completed:
        return 'Hoàn tất';
      case WeighingSessionStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

enum RiceVariety {
  om5451,
  daiThom8,
  st25,
  jasmine85,
  ir50404,
  nangHoa9,
  other;

  String get displayName {
    switch (this) {
      case RiceVariety.om5451:
        return 'OM 5451';
      case RiceVariety.daiThom8:
        return 'Đài Thơm 8';
      case RiceVariety.st25:
        return 'ST 25';
      case RiceVariety.jasmine85:
        return 'Jasmine 85';
      case RiceVariety.ir50404:
        return 'IR 50404';
      case RiceVariety.nangHoa9:
        return 'Nàng Hoa 9';
      case RiceVariety.other:
        return 'Giống lúa khác';
    }
  }

  static RiceVariety fromString(String? value) {
    if (value == null) return RiceVariety.om5451;
    return RiceVariety.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiceVariety.om5451,
    );
  }
}

enum WeightUnit {
  kg,
  tan,
  ta;

  String get symbol {
    switch (this) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.tan:
        return 'tấn';
      case WeightUnit.ta:
        return 'tạ';
    }
  }
}

enum VoiceReaderSpeed {
  slow,
  normal,
  fast;

  double get rate {
    switch (this) {
      case VoiceReaderSpeed.slow:
        return 0.95;
      case VoiceReaderSpeed.normal:
        return 1.15;
      case VoiceReaderSpeed.fast:
        return 1.35;
    }
  }

  String get label {
    switch (this) {
      case VoiceReaderSpeed.slow:
        return 'Chậm rãi (0.95x)';
      case VoiceReaderSpeed.normal:
        return 'Tự nhiên (1.15x)';
      case VoiceReaderSpeed.fast:
        return 'Nhanh hiện trường (1.35x)';
    }
  }

  String get description {
    switch (this) {
      case VoiceReaderSpeed.slow:
        return 'Phát âm thong thả, rõ từng chữ';
      case VoiceReaderSpeed.normal:
        return 'Tốc độ nói chuẩn, trong trẻo, tự nhiên';
      case VoiceReaderSpeed.fast:
        return 'Dành cho thợ cân vác bao liên tục';
    }
  }

  static VoiceReaderSpeed fromString(String? value) {
    if (value == null) return VoiceReaderSpeed.normal;
    return VoiceReaderSpeed.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VoiceReaderSpeed.normal,
    );
  }
}

enum VoiceReaderStyle {
  full,
  short,
  weightOnly;

  String get label {
    switch (this) {
      case VoiceReaderStyle.full:
        return 'Đầy đủ (Bao + Số ký)';
      case VoiceReaderStyle.short:
        return 'Rút gọn hiện trường';
      case VoiceReaderStyle.weightOnly:
        return 'Chỉ đọc số cân';
    }
  }

  String get example {
    switch (this) {
      case VoiceReaderStyle.full:
        return 'Bao 12, năm mươi hai ký rưỡi';
      case VoiceReaderStyle.short:
        return 'Bao 12: 52 rưỡi';
      case VoiceReaderStyle.weightOnly:
        return '52 ký rưỡi';
    }
  }

  static VoiceReaderStyle fromString(String? value) {
    if (value == null) return VoiceReaderStyle.full;
    return VoiceReaderStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VoiceReaderStyle.full,
    );
  }
}

enum ReceiptPaperSize {
  thermal58mm,
  thermal80mm,
  standardA4;

  String get label {
    switch (this) {
      case ReceiptPaperSize.thermal58mm:
        return 'In nhiệt K58 (58mm)';
      case ReceiptPaperSize.thermal80mm:
        return 'In nhiệt K80 (80mm)';
      case ReceiptPaperSize.standardA4:
        return 'Khổ giấy A4 tiêu chuẩn';
    }
  }
}

enum WeighingGroupingMode {
  continuous,
  groupedBatch;

  String get label {
    switch (this) {
      case WeighingGroupingMode.continuous:
        return 'Cân liên tục (chuẩn)';
      case WeighingGroupingMode.groupedBatch:
        return 'Phân nhóm & Đợt chốt tiền';
    }
  }

  static WeighingGroupingMode fromString(String? value) {
    if (value == null) return WeighingGroupingMode.groupedBatch;
    return WeighingGroupingMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WeighingGroupingMode.groupedBatch,
    );
  }
}

enum ReceiptPrintMode {
  fullDetail,
  batchSummary;

  String get label {
    switch (this) {
      case ReceiptPrintMode.fullDetail:
        return 'Chi tiết từng bao';
      case ReceiptPrintMode.batchSummary:
        return 'Tóm tắt theo đợt';
    }
  }

  String get description {
    switch (this) {
      case ReceiptPrintMode.fullDetail:
        return 'In đầy đủ danh sách tất cả các mã cân';
      case ReceiptPrintMode.batchSummary:
        return 'Gom tổng số ký và tiền theo từng đợt chốt';
    }
  }
}

