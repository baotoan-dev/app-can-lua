import 'package:flutter_test/flutter_test.dart';
import 'package:can_lua_app/core/enums/can_lua_enums.dart';
import 'package:can_lua_app/core/utils/vietnamese_number_reader.dart';

void main() {
  group('VietnameseNumberReader (Tiếng Việt có dấu)', () {
    test('Đọc số nguyên dưới 1000 chuẩn xác', () {
      expect(VietnameseNumberReader.readInteger(0), 'không');
      expect(VietnameseNumberReader.readInteger(5), 'năm');
      expect(VietnameseNumberReader.readInteger(10), 'mười');
      expect(VietnameseNumberReader.readInteger(12), 'mười hai');
      expect(VietnameseNumberReader.readInteger(15), 'mười lăm');
      expect(VietnameseNumberReader.readInteger(20), 'hai mươi');
      expect(VietnameseNumberReader.readInteger(21), 'hai mươi mốt');
      expect(VietnameseNumberReader.readInteger(24), 'hai mươi tư');
      expect(VietnameseNumberReader.readInteger(25), 'hai mươi lăm');
      expect(VietnameseNumberReader.readInteger(50), 'năm mươi');
      expect(VietnameseNumberReader.readInteger(54), 'năm mươi tư');
      expect(VietnameseNumberReader.readInteger(100), 'một trăm');
    });

    test('Đọc cân nặng lúa theo thuật ngữ nông nghiệp miền Tây', () {
      expect(VietnameseNumberReader.readWeightSpeech(50.0), 'năm mươi ký');
      expect(VietnameseNumberReader.readWeightSpeech(52.5), 'năm mươi hai ký rưỡi');
      expect(VietnameseNumberReader.readWeightSpeech(49.2), 'bốn mươi chín ký hai');
      expect(VietnameseNumberReader.readWeightSpeech(60.1), 'sáu mươi ký mốt');
    });

    test('Đọc đầy đủ cả số hiệu bao và cân nặng', () {
      expect(
        VietnameseNumberReader.readBagSpeech(1, 50.0),
        'Bao một, năm mươi ký',
      );
      expect(
        VietnameseNumberReader.readBagSpeech(12, 52.5),
        'Bao mười hai, năm mươi hai ký rưỡi',
      );
    });

    test('Đọc theo các kiểu câu VoiceReaderStyle linh hoạt', () {
      // Kiểu Đầy đủ (full)
      expect(
        VietnameseNumberReader.readBagSpeech(12, 52.5, style: VoiceReaderStyle.full),
        'Bao mười hai, năm mươi hai ký rưỡi',
      );

      // Kiểu Rút gọn hiện trường (short)
      expect(
        VietnameseNumberReader.readBagSpeech(12, 52.5, style: VoiceReaderStyle.short),
        'Bao 12: năm mươi hai rưỡi',
      );
      expect(
        VietnameseNumberReader.readBagSpeech(12, 50.0, style: VoiceReaderStyle.short),
        'Bao 12: năm mươi ký',
      );
      expect(
        VietnameseNumberReader.readBagSpeech(12, 51.1, style: VoiceReaderStyle.short),
        'Bao 12: năm mươi mốt mốt',
      );
      expect(
        VietnameseNumberReader.readBagSpeech(12, 49.2, style: VoiceReaderStyle.short),
        'Bao 12: bốn mươi chín hai',
      );

      // Kiểu Chỉ đọc số cân (weightOnly)
      expect(
        VietnameseNumberReader.readBagSpeech(12, 52.5, style: VoiceReaderStyle.weightOnly),
        'năm mươi hai ký rưỡi',
      );
      expect(
        VietnameseNumberReader.readBagSpeech(12, 50.0, style: VoiceReaderStyle.weightOnly),
        'năm mươi ký',
      );
    });
  });
}

