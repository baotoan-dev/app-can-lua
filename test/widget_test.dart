import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:can_lua_app/main.dart';
import 'package:can_lua_app/features/weighing/services/local_storage_service.dart';
import 'package:can_lua_app/features/weighing/services/tts_voice_service.dart';

void main() {
  testWidgets('CanLuaApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await LocalStorageService.init();
    final ttsService = TtsVoiceService(isEnabled: false);

    await tester.pumpWidget(CanLuaApp(
      storageService: storageService,
      ttsService: ttsService,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Sổ Cân Lúa - Nông Sản'), findsOneWidget);
    expect(find.text('CÂN LÚA MỚI'), findsOneWidget);
  });
}
