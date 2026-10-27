import '../enums/can_lua_enums.dart';

class VietnameseNumberReader {
  VietnameseNumberReader._();

  static const List<String> _digits = [
    'không',
    'một',
    'hai',
    'ba',
    'bốn',
    'năm',
    'sáu',
    'bảy',
    'tám',
    'chín',
  ];

  /// Đọc số nguyên dưới 1000 sang tiếng Việt có dấu chuẩn
  static String readInteger(int number) {
    if (number < 0) {
      return 'âm ${readInteger(-number)}';
    }
    if (number < 10) {
      return _digits[number];
    }
    if (number < 20) {
      final unit = number % 10;
      if (unit == 0) return 'mười';
      if (unit == 5) return 'mười lăm';
      return 'mười ${_digits[unit]}';
    }
    if (number < 100) {
      final ten = number ~/ 10;
      final unit = number % 10;
      final tenStr = '${_digits[ten]} mươi';
      if (unit == 0) return tenStr;
      if (unit == 1) return '$tenStr mốt';
      if (unit == 4) return '$tenStr tư';
      if (unit == 5) return '$tenStr lăm';
      return '$tenStr ${_digits[unit]}';
    }
    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      final hundredStr = '${_digits[hundred]} trăm';
      if (remainder == 0) return hundredStr;
      if (remainder < 10) return '$hundredStr lẻ ${_digits[remainder]}';
      return '$hundredStr ${readInteger(remainder)}';
    }
    return number.toString();
  }

  /// Đọc cân nặng bao lúa theo cách phát âm nông dân miền Tây (có dấu chuẩn)
  /// Ví dụ:
  /// 50.0 -> "năm mươi ký"
  /// 52.5 -> "năm mươi hai ký rưỡi"
  /// 49.2 -> "bốn mươi chín ký hai"
  /// 60.1 -> "sáu mươi ký mốt"
  static String readWeightSpeech(double weightKg) {
    final integerPart = weightKg.floor();
    final decimalPart = ((weightKg - integerPart) * 10).round();

    final intStr = readInteger(integerPart);

    if (decimalPart == 0) {
      return '$intStr ký';
    } else if (decimalPart == 5) {
      return '$intStr ký rưỡi';
    } else if (decimalPart == 1) {
      return '$intStr ký mốt';
    } else {
      return '$intStr ký ${_digits[decimalPart]}';
    }
  }

  /// Đọc bao theo cấu hình VoiceReaderStyle linh hoạt
  /// - Full: "Bao mười hai, năm mươi hai ký rưỡi"
  /// - Short: "Bao 12: năm mươi hai rưỡi" (tinh gọn, nhịp nhanh)
  /// - WeightOnly: "năm mươi hai ký rưỡi"
  static String readBagSpeech(
    int bagIndex,
    double weightKg, {
    VoiceReaderStyle style = VoiceReaderStyle.full,
  }) {
    switch (style) {
      case VoiceReaderStyle.weightOnly:
        return readWeightSpeech(weightKg);

      case VoiceReaderStyle.short:
        final integerPart = weightKg.floor();
        final decimalPart = ((weightKg - integerPart) * 10).round();
        final intStr = readInteger(integerPart);

        String weightShort;
        if (decimalPart == 0) {
          weightShort = '$intStr ký';
        } else if (decimalPart == 5) {
          weightShort = '$intStr rưỡi';
        } else if (decimalPart == 1) {
          weightShort = '$intStr mốt';
        } else {
          weightShort = '$intStr ${_digits[decimalPart]}';
        }
        return 'Bao $bagIndex: $weightShort';

      case VoiceReaderStyle.full:
        final bagStr = readInteger(bagIndex);
        final weightStr = readWeightSpeech(weightKg);
        return 'Bao $bagStr, $weightStr';
    }
  }
}

