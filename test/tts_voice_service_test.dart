import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:can_lua_app/core/enums/can_lua_enums.dart';
import 'package:can_lua_app/features/weighing/services/local_storage_service.dart';
import 'package:can_lua_app/features/weighing/services/tts_voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Voice Speed & Style Enum Verification', () {
    test('VoiceReaderSpeed trả về tốc độ tự nhiên chuẩn xác', () {
      expect(VoiceReaderSpeed.slow.rate, 0.95);
      expect(VoiceReaderSpeed.normal.rate, 1.15);
      expect(VoiceReaderSpeed.fast.rate, 1.35);

      expect(VoiceReaderSpeed.slow.label, contains('0.95x'));
      expect(VoiceReaderSpeed.normal.label, contains('1.15x'));
      expect(VoiceReaderSpeed.fast.label, contains('1.35x'));

      expect(VoiceReaderSpeed.fromString('fast'), VoiceReaderSpeed.fast);
      expect(VoiceReaderSpeed.fromString('slow'), VoiceReaderSpeed.slow);
      expect(VoiceReaderSpeed.fromString('unknown'), VoiceReaderSpeed.normal);
      expect(VoiceReaderSpeed.fromString(null), VoiceReaderSpeed.normal);
    });

    test('VoiceReaderStyle trả về đúng kiểu câu và mẫu ví dụ', () {
      expect(VoiceReaderStyle.full.label, contains('Đầy đủ'));
      expect(VoiceReaderStyle.short.label, contains('Rút gọn'));
      expect(VoiceReaderStyle.weightOnly.label, contains('Chỉ đọc số cân'));

      expect(VoiceReaderStyle.full.example, contains('năm mươi hai ký rưỡi'));
      expect(VoiceReaderStyle.short.example, contains('52 rưỡi'));
      expect(VoiceReaderStyle.weightOnly.example, '52 ký rưỡi');

      expect(VoiceReaderStyle.fromString('short'), VoiceReaderStyle.short);
      expect(VoiceReaderStyle.fromString('weightOnly'), VoiceReaderStyle.weightOnly);
      expect(VoiceReaderStyle.fromString(null), VoiceReaderStyle.full);
    });
  });

  group('LocalStorageService TTS Persistence', () {
    test('Lưu trữ và phục hồi VoiceReaderSpeed và VoiceReaderStyle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // Giá trị mặc định
      expect(storage.getTtsSpeed(), VoiceReaderSpeed.normal);
      expect(storage.getTtsStyle(), VoiceReaderStyle.full);
      expect(storage.isTtsEnabled(), true);

      // Thay đổi và lưu
      await storage.setTtsSpeed(VoiceReaderSpeed.fast);
      await storage.setTtsStyle(VoiceReaderStyle.short);
      await storage.setTtsEnabled(false);

      expect(storage.getTtsSpeed(), VoiceReaderSpeed.fast);
      expect(storage.getTtsStyle(), VoiceReaderStyle.short);
      expect(storage.isTtsEnabled(), false);
    });
  });

  group('TtsVoiceService Initialization & State', () {
    test('Khởi tạo đúng tốc độ và kiểu đọc mặc định', () async {
      final tts = TtsVoiceService();
      expect(tts.isEnabled, true);
      expect(tts.speed, VoiceReaderSpeed.normal);
      expect(tts.style, VoiceReaderStyle.full);

      await tts.setSpeed(VoiceReaderSpeed.fast);
      expect(tts.speed, VoiceReaderSpeed.fast);

      await tts.setStyle(VoiceReaderStyle.short);
      expect(tts.style, VoiceReaderStyle.short);
    });
  });
}
