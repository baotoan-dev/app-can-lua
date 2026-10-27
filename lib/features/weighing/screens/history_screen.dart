import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/file_share_helper.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_modal_dialog.dart';
import '../../../core/widgets/app_responsive_frame.dart';
import '../../../core/widgets/app_segmented_tab.dart';
import '../models/session_index_item.dart';
import '../models/weighing_session.dart';
import '../services/local_storage_service.dart';
import '../services/tts_voice_service.dart';
import 'receipt_preview_screen.dart';
import 'session_setup_screen.dart';
import 'weighing_screen.dart';

class HistoryScreen extends StatefulWidget {
  final LocalStorageService storageService;
  final TtsVoiceService ttsService;

  const HistoryScreen({
    super.key,
    required this.storageService,
    required this.ttsService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionIndexItem> _sessions = [];
  WeighingSessionStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _sessions = widget.storageService.getIndexListSync();
  }

  Future<void> _loadSessions() async {
    final list = widget.storageService.getIndexListSync();
    setState(() {
      _sessions = list;
    });
  }

  Future<void> _createNewSession() async {
    final defaultTare = widget.storageService.getDefaultTare();
    final defaultPrice = widget.storageService.getDefaultPrice();

    final newSession = await Navigator.push<WeighingSession>(
      context,
      MaterialPageRoute(
        builder: (ctx) => SessionSetupScreen(
          defaultTare: defaultTare,
          defaultPrice: defaultPrice,
        ),
      ),
    );

    if (newSession != null) {
      await widget.storageService.saveSession(newSession);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => WeighingScreen(
            session: newSession,
            storageService: widget.storageService,
            ttsService: widget.ttsService,
          ),
        ),
      );
      _loadSessions();
    }
  }

  Future<void> _openSession(String sessionId) async {
    final fullSession = await widget.storageService.getSessionById(sessionId);
    if (fullSession != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => WeighingScreen(
            session: fullSession,
            storageService: widget.storageService,
            ttsService: widget.ttsService,
          ),
        ),
      );
      _loadSessions();
    }
  }

  Future<void> _previewReceipt(String sessionId) async {
    final fullSession = await widget.storageService.getSessionById(sessionId);
    if (fullSession != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ReceiptPreviewScreen(session: fullSession),
        ),
      );
    }
  }

  Future<void> _deleteSession(SessionIndexItem session) async {
    final confirm = await AppModalDialog.showDeleteConfirmDialog(
      context: context,
      title: 'Xóa phiên cân?',
      message:
          'Bạn có chắc chắn muốn xóa vĩnh viễn phiếu cân của "${session.farmerName}" (${session.sessionCode}) gồm ${session.totalBags} bao lúa?',
      confirmLabel: 'Xóa vĩnh viễn',
    );

    if (confirm == true) {
      await widget.storageService.deleteSession(session.id);
      _loadSessions();
    }
  }

  Future<void> _handleBackup() async {
    final totalSessions = _sessions.length;
    final totalBags = _sessions.fold(0, (sum, s) => sum + s.totalBags);
    final totalNetKg = _sessions.fold(0.0, (sum, s) => sum + s.netWeight);
    final totalValue = _sessions.fold(0.0, (sum, s) => sum + s.totalAmount);

    await AppModalDialog.showBackupDialog(
      context: context,
      totalSessions: totalSessions,
      totalBags: totalBags,
      totalNetKg: totalNetKg,
      totalAmount: totalValue,
      onDownloadFile: () async {
        try {
          final json = await widget.storageService.exportBackupJson();
          final filename =
              'CanLua_SaoLuu_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
          await FileShareHelper.shareTextFile(
            content: json,
            filename: filename,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xuất tệp sao lưu: $filename'),
                backgroundColor: AppTheme.primary,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xuất tệp: $e'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
      onCopyJson: () async {
        try {
          final json = await widget.storageService.exportBackupJson();
          await Clipboard.setData(ClipboardData(text: json));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đã sao chép toàn bộ dữ liệu vào bộ nhớ tạm. Hãy dán vào Zalo để lưu trữ!',
                ),
                backgroundColor: AppTheme.primary,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi sao chép: $e'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _handleRestore() async {
    final result = await AppModalDialog.showRestoreDialog(context: context);
    if (result == null) return;

    final content = result['content'] as String;
    final replace = result['replace'] as bool;

    try {
      final count = await widget.storageService
          .importBackupJson(content, replace: replace);
      await _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Khôi phục thành công $count phiên cân vào sổ!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phục hồi dữ liệu: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleExportExcel() async {
    try {
      final csv = await widget.storageService.exportExcelCsv();
      final filename =
          'SoCanLua_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      await FileShareHelper.shareTextFile(
        content: csv,
        filename: filename,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xuất bảng tính Excel: $filename'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất bảng tính Excel: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = _sessions.length;
    final totalBags = _sessions.fold(0, (sum, s) => sum + s.totalBags);
    final totalNetKg = _sessions.fold(0.0, (sum, s) => sum + s.netWeight);
    final totalValue = _sessions.fold(0.0, (sum, s) => sum + s.totalAmount);

    return AppResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 24),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Sổ Cân Lúa - Nông Sản',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: _loadSessions,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Quản lý dữ liệu',
              onSelected: (value) {
                if (value == 'backup') {
                  _handleBackup();
                } else if (value == 'restore') {
                  _handleRestore();
                } else if (value == 'excel') {
                  _handleExportExcel();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'backup',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: AppTheme.primary, size: 20),
                      SizedBox(width: 10),
                      Text('Sao lưu sổ cân (Zalo/File)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.settings_backup_restore_rounded,
                          color: AppTheme.accent, size: 20),
                      SizedBox(width: 10),
                      Text('Phục hồi sổ cân'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart_outlined,
                          color: Colors.teal, size: 20),
                      SizedBox(width: 10),
                      Text('Xuất bảng tính Excel (.csv)'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.35),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text(
              'CÂN LÚA MỚI',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            onPressed: _createNewSession,
          ),
        ),
        body: Column(
          children: [
            // Aggregate Overview Banner
            Container(
              color: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem('SỐ PHIÊN', '$totalSessions', 'phiên'),
                  _buildMetricItem('TỔNG BAO', '$totalBags', 'bao'),
                  _buildMetricItem(
                    'SẢN LƯỢNG',
                    (totalNetKg / 1000).toStringAsFixed(2),
                    'tấn',
                  ),
                  _buildMetricItem(
                    'TỔNG TIỀN',
                    (totalValue / 1000000).toStringAsFixed(1),
                    'triệu',
                    color: Colors.amberAccent,
                  ),
                ],
              ),
            ),

            // Status Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AppSegmentedTab<WeighingSessionStatus?>(
                height: 42,
                selectedValue: _filterStatus,
                onTabChanged: (val) {
                  setState(() => _filterStatus = val);
                },
                items: [
                  AppTabItem(
                    value: null,
                    label: 'Tất cả',
                    badgeCount: _sessions.length,
                  ),
                  AppTabItem(
                    value: WeighingSessionStatus.draft,
                    label: 'Đang cân',
                    badgeCount: _sessions
                        .where((s) => s.status == WeighingSessionStatus.draft)
                        .length,
                  ),
                  AppTabItem(
                    value: WeighingSessionStatus.completed,
                    label: 'Hoàn tất',
                    badgeCount: _sessions
                        .where(
                            (s) => s.status == WeighingSessionStatus.completed)
                        .length,
                  ),
                ],
              ),
            ),

            // Sessions List
            Expanded(
              child: () {
                final displayedSessions = _filterStatus == null
                    ? _sessions
                    : _sessions
                        .where((s) => s.status == _filterStatus)
                        .toList();

                if (displayedSessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == null
                              ? 'Chưa có phiên cân nào'
                              : (_filterStatus == WeighingSessionStatus.draft
                                  ? 'Không có phiên nào đang cân'
                                  : 'Chưa có phiên cân nào hoàn tất'),
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bấm "CÂN LÚA MỚI" để tạo phiếu cân đầu tiên',
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  itemCount: displayedSessions.length,
                  itemBuilder: (context, index) {
                    final session = displayedSessions[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm')
                        .format(session.createdAt);
                    final isCompleted = session.status ==
                        WeighingSessionStatus.completed;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openSession(session.id),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            session.farmerName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? Colors.green.shade50
                                                  : Colors.amber.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isCompleted
                                                    ? Colors.green
                                                    : Colors.amber.shade700,
                                              ),
                                            ),
                                            child: Text(
                                              session.status.label,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isCompleted
                                                    ? Colors.green.shade800
                                                    : Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _deleteSession(session),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${session.sessionCode} | $dateStr | ${session.riceVariety.displayName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildDetailItem(
                                        'Số bao',
                                        '${session.totalBags} bao',
                                      ),
                                      _buildDetailItem(
                                        'Lúa sạch',
                                        CurrencyFormatter.formatWeight(
                                            session.netWeight),
                                      ),
                                      _buildDetailItem(
                                        'Thành tiền',
                                        CurrencyFormatter.formatVnd(
                                            session.totalAmount),
                                        highlight: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          icon: const Icon(Icons.receipt_long,
                                              size: 16),
                                          label: const Text(
                                            'Xem & In phiếu',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () =>
                                              _previewReceipt(session.id),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          icon: const Icon(Icons.edit_note,
                                              size: 16),
                                          label: Text(
                                            isCompleted
                                                ? 'Xem lại'
                                                : 'Tiếp tục cân',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () =>
                                              _openSession(session.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
              }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    String unit, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color ?? Colors.white,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
