import 'dart:async';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_responsive_frame.dart';
import 'features/weighing/services/local_storage_service.dart';
import 'features/weighing/services/tts_voice_service.dart';
import 'features/weighing/screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await LocalStorageService.init();
  final ttsService = TtsVoiceService(
    isEnabled: storageService.isTtsEnabled(),
  );
  // Khoi tao TTS ngam khong chan luong hien thi runApp
  unawaited(ttsService.init());

  runApp(CanLuaApp(
    storageService: storageService,
    ttsService: ttsService,
  ));
}

class CanLuaApp extends StatelessWidget {
  final LocalStorageService storageService;
  final TtsVoiceService ttsService;

  const CanLuaApp({
    super.key,
    required this.storageService,
    required this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Cân Lúa',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppResponsiveFrame(child: child ?? const SizedBox.shrink());
      },
      home: HistoryScreen(
        storageService: storageService,
        ttsService: ttsService,
      ),
    );
  }
}

