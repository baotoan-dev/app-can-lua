import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/utils/vietnamese_number_reader.dart';

class TtsVoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool isEnabled = true;
  VoiceReaderSpeed speed = VoiceReaderSpeed.normal;
  VoiceReaderStyle style = VoiceReaderStyle.full;

  TtsVoiceService({
    this.isEnabled = true,
    this.speed = VoiceReaderSpeed.normal,
    this.style = VoiceReaderStyle.full,
  });

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('vi-VN');
      await _flutterTts.setSpeechRate(speed.rate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if platform TTS engine is not available
    }
  }

  Future<void> setSpeed(VoiceReaderSpeed newSpeed) async {
    speed = newSpeed;
    if (_isInitialized) {
      try {
        await _flutterTts.setSpeechRate(speed.rate);
      } catch (_) {}
    }
  }

  Future<void> setStyle(VoiceReaderStyle newStyle) async {
    style = newStyle;
  }

  Future<void> speak(String text) async {
    if (!isEnabled) return;
    try {
      if (!_isInitialized) {
        await init();
      }
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> speakWeight(double weightKg) async {
    final text = VietnameseNumberReader.readWeightSpeech(weightKg);
    await speak(text);
  }

  Future<void> speakBag(int bagIndex, double weightKg) async {
    final text = VietnameseNumberReader.readBagSpeech(
      bagIndex,
      weightKg,
      style: style,
    );
    await speak(text);
  }

  /// Phát âm thanh mẫu để người dùng nghe thử cấu hình tốc độ và kiểu đọc
  Future<void> previewSampleSpeech({
    int sampleBag = 1,
    double sampleWeight = 52.5,
  }) async {
    final text = VietnameseNumberReader.readBagSpeech(
      sampleBag,
      sampleWeight,
      style: style,
    );
    await speak(text);
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}

