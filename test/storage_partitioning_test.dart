import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:can_lua_app/core/enums/can_lua_enums.dart';
import 'package:can_lua_app/features/weighing/models/bag_weight.dart';
import 'package:can_lua_app/features/weighing/models/weighing_session.dart';
import 'package:can_lua_app/features/weighing/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageService Partitioning Tests', () {
    test('Saves session into partitioned index and individual payload',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      final now = DateTime(2026, 10, 27, 9, 30);
      final session = WeighingSession(
        id: 'session_test_01',
        sessionCode: 'P-TEST-001',
        farmerName: 'Chú Bảy Cò',
        traderName: 'Thương lái Ba Tri',
        riceVariety: RiceVariety.st25,
        pricePerKg: 10500.0,
        tarePerBagKg: 0.3,
        createdAt: now,
        bags: List.generate(
          10,
          (i) => BagWeight(
            index: i + 1,
            grossWeight: 50.0 + i,
            recordedAt: now,
          ),
        ),
      );

      await storage.saveSession(session);

      // Verify index contains lightweight metadata
      final indexList = storage.getIndexListSync();
      expect(indexList.length, 1);
      final indexItem = indexList.first;
      expect(indexItem.id, 'session_test_01');
      expect(indexItem.farmerName, 'Chú Bảy Cò');
      expect(indexItem.totalBags, 10);
      expect(indexItem.riceVariety, RiceVariety.st25);

      // Verify raw SharedPreferences keys
      expect(prefs.containsKey('can_lua_sessions_index_v2'), isTrue);
      expect(prefs.containsKey('can_lua_session_session_test_01'), isTrue);

      // Verify lazy-loaded full session
      final loadedSession = storage.getSessionByIdSync('session_test_01');
      expect(loadedSession, isNotNull);
      expect(loadedSession!.bags.length, 10);
      expect(loadedSession.bags.first.grossWeight, 50.0);
      expect(loadedSession.bags.last.grossWeight, 59.0);
    });

    test('Deletes session from both index and individual payload', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      final session = WeighingSession(
        id: 'session_del_01',
        sessionCode: 'P-DEL-001',
        farmerName: 'Anh Năm',
        createdAt: DateTime.now(),
        bags: [
          BagWeight(
            index: 1,
            grossWeight: 50.0,
            recordedAt: DateTime.now(),
          ),
        ],
      );

      await storage.saveSession(session);
      expect(storage.getIndexListSync().length, 1);
      expect(prefs.containsKey('can_lua_session_session_del_01'), isTrue);

      await storage.deleteSession(session.id);
      expect(storage.getIndexListSync().length, 0);
      expect(prefs.containsKey('can_lua_session_session_del_01'), isFalse);
    });
  });

  group('LocalStorageService Auto-Migration Tests', () {
    test('Migrates legacy v1 monolithic format into partitioned v2', () async {
      final now = DateTime(2026, 5, 10, 8, 0);
      final legacySession = WeighingSession(
        id: 'legacy_01',
        sessionCode: 'P-LEGACY-001',
        farmerName: 'Bác Tám',
        riceVariety: RiceVariety.daiThom8,
        pricePerKg: 8500.0,
        createdAt: now,
        bags: [
          BagWeight(index: 1, grossWeight: 52.0, recordedAt: now),
          BagWeight(index: 2, grossWeight: 53.5, recordedAt: now),
        ],
      );

      final legacyJson = jsonEncode([legacySession.toJson()]);
      SharedPreferences.setMockInitialValues({
        'can_lua_sessions_v1': legacyJson,
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('can_lua_sessions_v1'), isTrue);

      // Initialize service which triggers auto-migration
      final storage = LocalStorageService(prefs);

      // Legacy key must be purged
      expect(prefs.containsKey('can_lua_sessions_v1'), isFalse);

      // Partitioned keys must exist
      expect(prefs.containsKey('can_lua_sessions_index_v2'), isTrue);
      expect(prefs.containsKey('can_lua_session_legacy_01'), isTrue);

      // Data integrity verification
      final indexList = storage.getIndexListSync();
      expect(indexList.length, 1);
      expect(indexList.first.farmerName, 'Bác Tám');
      expect(indexList.first.totalBags, 2);

      final fullSession = storage.getSessionByIdSync('legacy_01');
      expect(fullSession, isNotNull);
      expect(fullSession!.bags.length, 2);
      expect(fullSession.riceVariety, RiceVariety.daiThom8);
    });
  });

  group('Backup, Restore & Excel Export Tests', () {
    test('Exports JSON backup and restores seamlessly', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      final now = DateTime(2026, 10, 1);
      final session1 = WeighingSession(
        id: 'sess_1',
        sessionCode: 'P-001',
        farmerName: 'Chủ Ruộng 1',
        createdAt: now,
        bags: [BagWeight(index: 1, grossWeight: 50.0, recordedAt: now)],
      );

      final session2 = WeighingSession(
        id: 'sess_2',
        sessionCode: 'P-002',
        farmerName: 'Chủ Ruộng 2',
        createdAt: DateTime(2026, 10, 2),
        bags: [
          BagWeight(index: 1, grossWeight: 55.0, recordedAt: now),
          BagWeight(index: 2, grossWeight: 56.0, recordedAt: now),
        ],
      );

      await storage.saveSession(session1);
      await storage.saveSession(session2);

      // Export backup
      final backupJson = await storage.exportBackupJson();
      expect(backupJson, contains('SoCanLua'));
      expect(backupJson, contains('Chủ Ruộng 1'));
      expect(backupJson, contains('Chủ Ruộng 2'));

      // Delete session 1
      await storage.deleteSession('sess_1');
      expect(storage.getIndexListSync().length, 1);

      // Restore without replace (merge)
      final importedCount =
          await storage.importBackupJson(backupJson, replace: false);
      expect(importedCount, 2);
      expect(storage.getIndexListSync().length, 2);

      final restoredSession1 = storage.getSessionByIdSync('sess_1');
      expect(restoredSession1, isNotNull);
      expect(restoredSession1!.farmerName, 'Chủ Ruộng 1');
      expect(restoredSession1.bags.length, 1);

      // Verify backward compatibility: importing legacy backup with FieldProof_CanLua tag
      final legacyBackupJson = backupJson.replaceAll('SoCanLua', 'FieldProof_CanLua');
      final legacyImported = await storage.importBackupJson(legacyBackupJson, replace: true);
      expect(legacyImported, 2);
      expect(storage.getIndexListSync().length, 2);
    });

    test('Exports Excel CSV with UTF-8 BOM and correct headers', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      final now = DateTime(2026, 10, 27, 10, 0);
      final session = WeighingSession(
        id: 'sess_csv',
        sessionCode: 'P-CSV-999',
        farmerName: 'Trần Văn Lúa',
        traderName: 'Công ty Lương Thực Cần Thơ',
        riceVariety: RiceVariety.om5451,
        pricePerKg: 9000.0,
        tarePerBagKg: 0.2,
        createdAt: now,
        status: WeighingSessionStatus.completed,
        bags: [
          BagWeight(index: 1, grossWeight: 50.2, recordedAt: now),
          BagWeight(index: 2, grossWeight: 50.2, recordedAt: now),
        ],
      );

      await storage.saveSession(session);

      final csv = await storage.exportExcelCsv();

      // Check UTF-8 BOM
      expect(csv.startsWith('\uFEFF'), isTrue);

      // Check headers
      expect(csv, contains('Mã Phiếu,Ngày Cân,Chủ Ruộng,Thương Lái'));

      // Check data row
      expect(csv, contains('P-CSV-999'));
      expect(csv, contains('Trần Văn Lúa'));
      expect(csv, contains('Công ty Lương Thực Cần Thơ'));
      expect(csv, contains('OM 5451'));
      expect(csv, contains('Hoàn tất'));
    });
  });
}
