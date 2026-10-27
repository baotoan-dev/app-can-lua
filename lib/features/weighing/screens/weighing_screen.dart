import 'package:flutter/material.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_modal_dialog.dart';
import '../../../core/widgets/app_responsive_frame.dart';
import '../models/bag_weight.dart';
import '../models/weighing_session.dart';
import '../services/local_storage_service.dart';
import '../services/tts_voice_service.dart';
import '../widgets/bag_grid_matrix.dart';
import '../widgets/custom_numpad.dart';
import '../widgets/live_summary_bar.dart';
import 'receipt_preview_screen.dart';
import 'session_setup_screen.dart';

class WeighingScreen extends StatefulWidget {
  final WeighingSession session;
  final LocalStorageService storageService;
  final TtsVoiceService ttsService;

  const WeighingScreen({
    super.key,
    required this.session,
    required this.storageService,
    required this.ttsService,
  });

  @override
  State<WeighingScreen> createState() => _WeighingScreenState();
}

class _WeighingScreenState extends State<WeighingScreen> {
  late WeighingSession _session;
  final ScrollController _scrollController = ScrollController();
  String _inputBuffer = '';
  bool _isTtsActive = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _isTtsActive = widget.storageService.isTtsEnabled();
    widget.ttsService.isEnabled = _isTtsActive;
    widget.ttsService.speed = widget.storageService.getTtsSpeed();
    widget.ttsService.style = widget.storageService.getTtsStyle();
    widget.ttsService.init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveCurrentSession() async {
    await widget.storageService.saveSession(_session);
  }

  void _onDigitPress(String digit) {
    if (digit == '.') {
      if (_inputBuffer.contains('.')) return;
      if (_inputBuffer.isEmpty) {
        setState(() => _inputBuffer = '0.');
        return;
      }
    }
    // Limit max 6 chars (e.g. 150.25)
    if (_inputBuffer.length >= 6) return;

    setState(() {
      _inputBuffer += digit;
    });
  }

  void _onDeletePress() {
    if (_inputBuffer.isNotEmpty) {
      setState(() {
        _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
      });
    }
  }

  void _onClearPress() {
    if (_inputBuffer.isNotEmpty) {
      setState(() {
        _inputBuffer = '';
      });
    }
  }

  void _onQuickAdd(double delta) {
    double current = double.tryParse(_inputBuffer) ?? 50.0;
    current += delta;
    setState(() {
      _inputBuffer = current.toStringAsFixed(1).replaceAll('.0', '');
    });
  }

  Future<void> _submitBag() async {
    final weight = double.tryParse(_inputBuffer);
    if (weight == null || weight <= 0 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số ký hợp lệ (từ 1 đến 500 kg)'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final newIndex = _session.totalBags + 1;
    final newBag = BagWeight(
      index: newIndex,
      grossWeight: weight,
      recordedAt: DateTime.now(),
    );

    final updatedBags = List<BagWeight>.from(_session.bags)..add(newBag);

    setState(() {
      _session = _session.copyWith(bags: updatedBags);
      _inputBuffer = '';
    });

    await _saveCurrentSession();
    _scrollToBottom();

    // Voice reading in Vietnamese
    if (_isTtsActive) {
      widget.ttsService.speakBag(newIndex, weight);
    }
  }

  Future<void> _handleBagTap(BagWeight bag) async {
    final result = await AppModalDialog.showEditBagDialog(
      context: context,
      bagIndex: bag.index,
      currentWeight: bag.grossWeight,
      pricePerKg: _session.pricePerKg,
      totalBags: _session.bags.length,
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        _deleteBag(bag.index);
      } else if (result['action'] == 'update' && result['weight'] != null) {
        _updateBag(bag.index, result['weight'] as double);
      }
    }
  }

  Future<void> _updateBag(int index, double newWeight) async {
    final updatedBags = _session.bags.map((b) {
      if (b.index == index) {
        return b.copyWith(grossWeight: newWeight);
      }
      return b;
    }).toList();

    setState(() {
      _session = _session.copyWith(bags: updatedBags);
    });
    await _saveCurrentSession();
  }

  Future<void> _deleteBag(int index) async {
    final bagToDelete = _session.bags.firstWhere(
      (b) => b.index == index,
      orElse: () => BagWeight(
        index: index,
        grossWeight: 0,
        recordedAt: DateTime.now(),
      ),
    );
    final filtered = _session.bags.where((b) => b.index != index).toList();
    // Re-index remaining bags
    final reindexed = List<BagWeight>.generate(filtered.length, (i) {
      return filtered[i].copyWith(index: i + 1);
    });

    setState(() {
      _session = _session.copyWith(bags: reindexed);
    });
    await _saveCurrentSession();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa bao #${bagToDelete.index} (${bagToDelete.grossWeight.toStringAsFixed(1)} kg). Đã dời thứ tự ${filtered.length} bao còn lại.',
            style: const TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleTts() {
    setState(() {
      _isTtsActive = !_isTtsActive;
    });
    widget.ttsService.isEnabled = _isTtsActive;
    widget.storageService.setTtsEnabled(_isTtsActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTtsActive
            ? 'Đã bật đọc giọng nói'
            : 'Đã tắt đọc giọng nói (chế độ im lặng)'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openTtsSettings() async {
    final result = await AppModalDialog.showTtsSettingsDialog(
      context: context,
      initialEnabled: _isTtsActive,
      initialSpeed: widget.storageService.getTtsSpeed(),
      initialStyle: widget.storageService.getTtsStyle(),
      ttsService: widget.ttsService,
    );

    if (result != null) {
      final enabled = result['enabled'] as bool;
      final speed = result['speed'] as VoiceReaderSpeed;
      final style = result['style'] as VoiceReaderStyle;

      setState(() {
        _isTtsActive = enabled;
      });

      widget.ttsService.isEnabled = enabled;
      await widget.ttsService.setSpeed(speed);
      await widget.ttsService.setStyle(style);

      await widget.storageService.setTtsEnabled(enabled);
      await widget.storageService.setTtsSpeed(speed);
      await widget.storageService.setTtsStyle(style);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật giọng đọc: ${speed.label} - ${style.label}',
              style: const TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openSessionSettings() async {
    final updated = await Navigator.push<WeighingSession>(
      context,
      MaterialPageRoute(
        builder: (ctx) => SessionSetupScreen(initialSession: _session),
      ),
    );

    if (updated != null) {
      setState(() {
        _session = updated;
      });
      await _saveCurrentSession();
    }
  }

  Future<void> _completeSession() async {
    if (_session.totalBags == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có bao nào, không thể hoàn tất phiếu'),
        ),
      );
      return;
    }

    final confirmed = await AppModalDialog.showSessionSummaryDialog(
      context: context,
      totalBags: _session.totalBags,
      netWeightKg: _session.netWeight,
      remainingPayableVnd: _session.remainingPayable,
      totalGrossWeightKg: _session.totalGrossWeight,
    );

    if (confirmed == true) {
      setState(() {
        _session = _session.copyWith(
          status: WeighingSessionStatus.completed,
          completedAt: DateTime.now(),
        );
      });
      await _saveCurrentSession();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ReceiptPreviewScreen(session: _session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                _session.farmerName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_session.riceVariety.displayName} - ${_session.sessionCode}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onLongPress: _openTtsSettings,
              child: IconButton(
                icon: Icon(
                  _isTtsActive ? Icons.volume_up : Icons.volume_off,
                  color: _isTtsActive ? Colors.amberAccent : Colors.white60,
                ),
                tooltip: 'Bật/Tắt đọc giọng nói (Nhấn giữ để cài đặt)',
                onPressed: _toggleTts,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Xem phiếu cân',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ReceiptPreviewScreen(session: _session),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'tts_settings') {
                  _openTtsSettings();
                } else if (val == 'settings') {
                  _openSessionSettings();
                } else if (val == 'complete') {
                  _completeSession();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'tts_settings',
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 8),
                      Text('Cài đặt giọng đọc'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Sửa thông tin phiếu'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 20, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Hoàn tất & Khóa sổ'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Live calculation summary
            LiveSummaryBar(session: _session),

            // Scrollable Bag Matrix
            Expanded(
              child: BagGridMatrix(
                session: _session,
                columnsPerRow: 5,
                scrollController: _scrollController,
                onBagTap: _handleBagTap,
              ),
            ),

            // Rapid Numpad
            CustomNumpad(
              currentInput: _inputBuffer,
              nextBagIndex: _session.totalBags + 1,
              onDigitPress: _onDigitPress,
              onDeletePress: _onDeletePress,
              onClearPress: _onClearPress,
              onQuickAdd: _onQuickAdd,
              onSubmit: _submitBag,
            ),
          ],
        ),
      ),
    );
  }
}

