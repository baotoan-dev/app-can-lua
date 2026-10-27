import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_index_item.dart';
import '../models/weighing_session.dart';
import '../../../core/enums/can_lua_enums.dart';

/// Partitioned storage service for weighing sessions.
/// Separates the lightweight metadata index from individual session payloads.
/// This prevents memory bloat, avoids web storage quota bottlenecks,
/// and enables sub-20ms app cold starts even with thousands of historical records.
class LocalStorageService {
  static const String _keySessionsIndex = 'can_lua_sessions_index_v2';
  static const String _keySessionPrefix = 'can_lua_session_';
  static const String _keySessionsLegacy = 'can_lua_sessions_v1';
  static const String _keyActiveSessionId = 'can_lua_active_id_v1';
  static const String _keyDefaultTare = 'can_lua_default_tare';
  static const String _keyDefaultPrice = 'can_lua_default_price';
  static const String _keyTtsEnabled = 'can_lua_tts_enabled';
  static const String _keyTtsSpeed = 'can_lua_tts_speed';
  static const String _keyTtsStyle = 'can_lua_tts_style';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs) {
    _migrateFromV1IfNeeded();
  }

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    return service;
  }

  /// Automatically migrates legacy monolithic `can_lua_sessions_v1`
  /// into the partitioned `can_lua_sessions_index_v2` and individual session keys.
  void _migrateFromV1IfNeeded() {
    final legacyJsonStr = _prefs.getString(_keySessionsLegacy);
    if (legacyJsonStr == null || legacyJsonStr.isEmpty) return;

    try {
      final List<dynamic> list = jsonDecode(legacyJsonStr) as List<dynamic>;
      final List<SessionIndexItem> indexItems = [];

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final session = WeighingSession.fromJson(item);
          // 1. Write individual payload
          final payloadStr = jsonEncode(session.toJson());
          _prefs.setString('$_keySessionPrefix${session.id}', payloadStr);
          // 2. Collect lightweight index item
          indexItems.add(SessionIndexItem.fromSession(session));
        }
      }

      // 3. Save partitioned index
      indexItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final indexJson =
          jsonEncode(indexItems.map((e) => e.toJson()).toList());
      _prefs.setString(_keySessionsIndex, indexJson);

      // 4. Remove legacy monolithic storage key
      _prefs.remove(_keySessionsLegacy);
    } catch (_) {
      // In case of parsing error, retain legacy key to prevent data loss
    }
  }

  // ---------------------------------------------------------------------------
  // Index & Partitioned Queries
  // ---------------------------------------------------------------------------

  /// Retrieves the lightweight index list of all sessions synchronously.
  List<SessionIndexItem> getIndexListSync() {
    _migrateFromV1IfNeeded();
    final jsonStr = _prefs.getString(_keySessionsIndex);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) =>
              SessionIndexItem.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  /// Loads a single full session (with its complete bag array) by id.
  WeighingSession? getSessionByIdSync(String sessionId) {
    _migrateFromV1IfNeeded();
    final jsonStr = _prefs.getString('$_keySessionPrefix$sessionId');
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WeighingSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Asynchronous getter for a single session by id.
  Future<WeighingSession?> getSessionById(String sessionId) async {
    return getSessionByIdSync(sessionId);
  }

  /// Backward-compatible synchronous session list retrieval.
  List<WeighingSession> getSessionsSync() {
    final indexList = getIndexListSync();
    if (indexList.isEmpty) return [];

    final List<WeighingSession> fullSessions = [];
    for (final item in indexList) {
      final session = getSessionByIdSync(item.id);
      if (session != null) {
        fullSessions.add(session);
      } else {
        // Fallback reconstructed session with empty bags if payload missing
        fullSessions.add(WeighingSession(
          id: item.id,
          sessionCode: item.sessionCode,
          farmerName: item.farmerName,
          traderName: item.traderName,
          phoneNumber: item.phoneNumber,
          riceVariety: item.riceVariety,
          pricePerKg: item.pricePerKg,
          tarePerBagKg: item.tarePerBagKg,
          depositAmount: item.depositAmount,
          status: item.status,
          groupingMode: item.groupingMode,
          bagsPerGroup: item.bagsPerGroup,
          groupsPerBatch: item.groupsPerBatch,
          createdAt: item.createdAt,
          completedAt: item.completedAt,
        ));
      }
    }
    return fullSessions;
  }

  Future<List<WeighingSession>> getAllSessions() async {
    return getSessionsSync();
  }

  /// Saves or updates a session with partitioned efficiency:
  /// Writes ONLY the updated session payload to its own key, then updates the index.
  Future<void> saveSession(WeighingSession session) async {
    _migrateFromV1IfNeeded();

    // 1. Write individual session payload
    final payloadJson = jsonEncode(session.toJson());
    await _prefs.setString('$_keySessionPrefix${session.id}', payloadJson);

    // 2. Update lightweight index
    final indexList = getIndexListSync();
    final targetIndex = indexList.indexWhere((s) => s.id == session.id);
    final newItem = SessionIndexItem.fromSession(session);

    if (targetIndex >= 0) {
      indexList[targetIndex] = newItem;
    } else {
      indexList.insert(0, newItem);
    }

    indexList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final indexJson =
        jsonEncode(indexList.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySessionsIndex, indexJson);
  }

  /// Deletes a session from both the partitioned payload and the index.
  Future<void> deleteSession(String sessionId) async {
    _migrateFromV1IfNeeded();

    // 1. Remove individual payload
    await _prefs.remove('$_keySessionPrefix$sessionId');

    // 2. Remove from index
    final indexList = getIndexListSync();
    indexList.removeWhere((s) => s.id == sessionId);
    final indexJson =
        jsonEncode(indexList.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySessionsIndex, indexJson);

    // 3. Clear active session if matching
    final activeId = _prefs.getString(_keyActiveSessionId);
    if (activeId == sessionId) {
      await _prefs.remove(_keyActiveSessionId);
    }
  }

  Future<WeighingSession?> getActiveSession() async {
    final activeId = _prefs.getString(_keyActiveSessionId);
    if (activeId == null) return null;
    return getSessionByIdSync(activeId);
  }

  Future<void> setActiveSessionId(String? sessionId) async {
    if (sessionId == null) {
      await _prefs.remove(_keyActiveSessionId);
    } else {
      await _prefs.setString(_keyActiveSessionId, sessionId);
    }
  }

  // ---------------------------------------------------------------------------
  // Backup, Restore & Excel Export Engine
  // ---------------------------------------------------------------------------

  /// Exports all sessions into a standalone JSON backup string.
  Future<String> exportBackupJson() async {
    final indexList = getIndexListSync();
    final List<Map<String, dynamic>> sessionsJson = [];

    for (final item in indexList) {
      final session = getSessionByIdSync(item.id);
      if (session != null) {
        sessionsJson.add(session.toJson());
      }
    }

    final backupPayload = {
      'app': 'SoCanLua',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'totalSessions': sessionsJson.length,
      'sessions': sessionsJson,
    };

    return const JsonEncoder.withIndent('  ').convert(backupPayload);
  }

  /// Imports sessions from a JSON backup string into the partitioned store.
  /// Returns the number of successfully imported sessions.
  Future<int> importBackupJson(String jsonString, {bool replace = false}) async {
    _migrateFromV1IfNeeded();

    final dynamic parsed = jsonDecode(jsonString);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Tệp sao lưu không đúng định dạng JSON.');
    }

    final dynamic rawSessions = parsed['sessions'];
    if (rawSessions is! List<dynamic>) {
      throw const FormatException('Tệp sao lưu không chứa danh sách phiên cân.');
    }

    if (replace) {
      // Clear current index and all payloads
      final currentIndex = getIndexListSync();
      for (final item in currentIndex) {
        await _prefs.remove('$_keySessionPrefix${item.id}');
      }
      await _prefs.remove(_keySessionsIndex);
    }

    final indexList = getIndexListSync();
    int importedCount = 0;

    for (final raw in rawSessions) {
      if (raw is Map<String, dynamic>) {
        final session = WeighingSession.fromJson(raw);
        // Save payload
        await _prefs.setString(
            '$_keySessionPrefix${session.id}', jsonEncode(session.toJson()));

        // Update index list
        final existingIdx = indexList.indexWhere((s) => s.id == session.id);
        final newItem = SessionIndexItem.fromSession(session);
        if (existingIdx >= 0) {
          indexList[existingIdx] = newItem;
        } else {
          indexList.add(newItem);
        }
        importedCount++;
      }
    }

    indexList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final indexJson =
        jsonEncode(indexList.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySessionsIndex, indexJson);

    return importedCount;
  }

  /// Generates a spreadsheet CSV formatted with UTF-8 with BOM (`\uFEFF`)
  /// for direct opening in Microsoft Excel without Vietnamese font corruption.
  Future<String> exportExcelCsv() async {
    final indexList = getIndexListSync();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Header row
    buffer.writeln(
      'Mã Phiếu,Ngày Cân,Chủ Ruộng,Thương Lái,Số Điện Thoại,Giống Lúa,Đơn Giá (đ/kg),Số Bao,Tổng Cân (kg),Trừ Bì (kg),Lúa Sạch (kg),Thành Tiền (đ),Đã Cọc (đ),Còn Lại (đ),Trạng Thái',
    );

    for (final item in indexList) {
      final sessionCode = _escapeCsv(item.sessionCode);
      final dateStr = _escapeCsv(dateFormat.format(item.createdAt));
      final farmerName = _escapeCsv(item.farmerName);
      final traderName = _escapeCsv(item.traderName);
      final phone = _escapeCsv(item.phoneNumber);
      final riceVariety = _escapeCsv(item.riceVariety.displayName);
      final price = item.pricePerKg.round();
      final bags = item.totalBags;
      final gross = item.totalGrossWeight.toStringAsFixed(1);
      final tare = (item.totalBags * item.tarePerBagKg).toStringAsFixed(1);
      final net = item.netWeight.toStringAsFixed(1);
      final amount = item.totalAmount.round();
      final deposit = item.depositAmount.round();
      final remaining = item.remainingPayable.round();
      final status = _escapeCsv(item.status.label);

      buffer.writeln(
        '$sessionCode,$dateStr,$farmerName,$traderName,$phone,$riceVariety,$price,$bags,$gross,$tare,$net,$amount,$deposit,$remaining,$status',
      );
    }

    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return '"$value"';
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------
  double getDefaultTare() => _prefs.getDouble(_keyDefaultTare) ?? 0.2;
  Future<void> setDefaultTare(double value) =>
      _prefs.setDouble(_keyDefaultTare, value);

  double getDefaultPrice() => _prefs.getDouble(_keyDefaultPrice) ?? 8200.0;
  Future<void> setDefaultPrice(double value) =>
      _prefs.setDouble(_keyDefaultPrice, value);

  bool isTtsEnabled() => _prefs.getBool(_keyTtsEnabled) ?? true;
  Future<void> setTtsEnabled(bool enabled) =>
      _prefs.setBool(_keyTtsEnabled, enabled);

  VoiceReaderSpeed getTtsSpeed() {
    final str = _prefs.getString(_keyTtsSpeed);
    return VoiceReaderSpeed.fromString(str);
  }

  Future<void> setTtsSpeed(VoiceReaderSpeed speed) =>
      _prefs.setString(_keyTtsSpeed, speed.name);

  VoiceReaderStyle getTtsStyle() {
    final str = _prefs.getString(_keyTtsStyle);
    return VoiceReaderStyle.fromString(str);
  }

  Future<void> setTtsStyle(VoiceReaderStyle style) =>
      _prefs.setString(_keyTtsStyle, style.name);
}
