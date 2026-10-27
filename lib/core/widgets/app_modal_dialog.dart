import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../enums/can_lua_enums.dart';
import '../../features/weighing/services/tts_voice_service.dart';

class AppModalDialog {
  AppModalDialog._();

  /// Hộp thoại chỉnh sửa số ký của một bao lúa dạng Modal Bottom Sheet hiện đại chuẩn iOS
  /// Hộp thoại chỉnh sửa số ký của một bao lúa dạng Modal Bottom Sheet hiện đại chuẩn iOS
  /// Tích hợp quy trình xác nhận 2 bước an toàn chống bấm nhầm xóa bao,
  /// hiển thị chênh lệch tài chính tức thì và bàn phím xúc giác 48px công thái học.
  static Future<Map<String, dynamic>?> showEditBagDialog({
    required BuildContext context,
    required int bagIndex,
    required double currentWeight,
    double? pricePerKg,
    int? totalBags,
  }) {
    String buffer = currentWeight.toStringAsFixed(1).replaceAll('.0', '');
    bool isConfirmingDelete = false;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            double parsed = double.tryParse(buffer) ?? currentWeight;
            double diff = parsed - currentWeight;
            double? moneyDiff = (pricePerKg != null && pricePerKg > 0)
                ? diff * pricePerKg
                : null;

            void applyDelta(double delta) {
              HapticFeedback.lightImpact();
              double newVal = parsed + delta;
              if (newVal < 0) newVal = 0;
              newVal = double.parse(newVal.toStringAsFixed(1));
              buffer = newVal.toStringAsFixed(1).replaceAll('.0', '');
              setSheetState(() {});
            }

            void onDigit(String digit) {
              HapticFeedback.lightImpact();
              if (digit == '.') {
                if (buffer.contains('.')) return;
                if (buffer.isEmpty) buffer = '0';
                buffer += '.';
              } else {
                if (buffer == '0') {
                  buffer = digit;
                } else {
                  if (buffer.length < 5) {
                    buffer += digit;
                  }
                }
              }
              setSheetState(() {});
            }

            void onBackspace() {
              HapticFeedback.lightImpact();
              if (buffer.isNotEmpty) {
                buffer = buffer.substring(0, buffer.length - 1);
                if (buffer.isEmpty) buffer = '0';
                setSheetState(() {});
              }
            }

            void onClear() {
              HapticFeedback.mediumImpact();
              buffer = '0';
              setSheetState(() {});
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(sheetCtx).padding.bottom + 16,
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                child: isConfirmingDelete
                    ? _buildDeleteConfirmationView(
                        bagIndex: bagIndex,
                        currentWeight: currentWeight,
                        totalBags: totalBags,
                        onCancel: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => isConfirmingDelete = false);
                        },
                        onConfirmDelete: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(ctx, {'action': 'delete'});
                        },
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle Indicator
                          Center(
                            child: Container(
                              width: 42,
                              height: 4.5,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),

                          // Header Row: Title + Delete Trigger + Close Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CHỈNH SỬA BAO #$bagIndex',
                                    style: const TextStyle(
                                      fontFamily: 'Be Vietnam Pro',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Separated Safe Delete Button
                                  IconButton(
                                    tooltip: 'Xóa bao này',
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      setSheetState(() => isConfirmingDelete = true);
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFEBEE),
                                      foregroundColor: AppTheme.error,
                                      padding: const EdgeInsets.all(7),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    onPressed: () => Navigator.pop(sheetCtx),
                                    icon: const Icon(Icons.close_rounded, size: 22),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      foregroundColor: Colors.grey.shade700,
                                      padding: const EdgeInsets.all(7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Hero Weight Readout Card with Financial Impact
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8F4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD6E2D6), width: 1.2),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      buffer.isEmpty ? '0' : buffer,
                                      style: const TextStyle(
                                        fontFamily: 'Be Vietnam Pro',
                                        fontFeatures: [FontFeature.tabularFigures()],
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F2913),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'kg',
                                      style: TextStyle(
                                        fontFamily: 'Be Vietnam Pro',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Gốc: ${currentWeight.toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        fontFamily: 'Be Vietnam Pro',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (diff.abs() >= 0.05) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: diff > 0
                                              ? const Color(0xFFE8F5E9)
                                              : const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: diff > 0
                                                ? const Color(0xFFA5D6A7)
                                                : const Color(0xFFFFCDD2),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          moneyDiff != null
                                              ? '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg (${diff > 0 ? '+' : ''}${CurrencyFormatter.formatVnd(moneyDiff)})'
                                              : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                                          style: TextStyle(
                                            fontFamily: 'Be Vietnam Pro',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: diff > 0 ? AppTheme.primary : AppTheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quick Micro-Adjustment Stepper: [-1.0] [-0.1] [+0.1] [+1.0]
                          Row(
                            children: [
                              Expanded(child: _buildStepperButton('-1.0', () => applyDelta(-1.0))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStepperButton('-0.1', () => applyDelta(-0.1))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStepperButton('+0.1', () => applyDelta(0.1))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStepperButton('+1.0', () => applyDelta(1.0))),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Integrated Tactile Ergonomic Numpad (3x4 with 48px height)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF8),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8E2)),
                            ),
                            child: Column(
                              children: [
                                _buildNumpadRow(['1', '2', '3'], onDigit),
                                const SizedBox(height: 8),
                                _buildNumpadRow(['4', '5', '6'], onDigit),
                                const SizedBox(height: 8),
                                _buildNumpadRow(['7', '8', '9'], onDigit),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _buildKeyBtn('.', () => onDigit('.'))),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildKeyBtn('0', () => onDigit('0'))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildIconKeyBtn(
                                        Icons.backspace_outlined,
                                        onBackspace,
                                        onLongPress: onClear,
                                        color: Colors.amber.shade900,
                                        bgColor: const Color(0xFFFFF8E1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Full-Width Save Button (Height 52px)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                              ),
                              onPressed: () {
                                final w = double.tryParse(buffer);
                                if (w != null && w > 0) {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(ctx, {
                                    'action': 'update',
                                    'weight': w,
                                  });
                                }
                              },
                              child: Text(
                                'LƯU SỐ CÂN (${(double.tryParse(buffer) ?? 0).toStringAsFixed(1)} KG)',
                                style: const TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildDeleteConfirmationView({
    required int bagIndex,
    required double currentWeight,
    int? totalBags,
    required VoidCallback onCancel,
    required VoidCallback onConfirmDelete,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag Handle Indicator
        Center(
          child: Container(
            width: 42,
            height: 4.5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Warning Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'XÁC NHẬN XÓA BAO #$bagIndex?',
              style: const TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.error,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Detail Warning Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bao số #$bagIndex có khối lượng ${currentWeight.toStringAsFixed(1)} kg sẽ bị xóa khỏi phiếu cân.',
                style: const TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7F1D1D),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (totalBags != null && totalBags > bagIndex)
                    ? 'Thứ tự các bao từ #${bagIndex + 1} đến #$totalBags sẽ tự động được dời lại 1 số thứ tự.'
                    : 'Thao tác xóa không thể hoàn tác.',
                style: const TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF991B1B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons Row: Cancel (left) + Confirm Delete (right)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onCancel,
                  child: const Text(
                    'HỦY BỎ',
                    style: TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    elevation: 1.5,
                    shadowColor: AppTheme.error.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onConfirmDelete,
                  child: const Text(
                    'XÓA BAO NÀY',
                    style: TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildStepperButton(String text, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0.8,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6DDD6), width: 1.0),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildNumpadRow(List<String> digits, Function(String) onDigit) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildKeyBtn(digits[i], () => onDigit(digits[i]))),
        ],
      ],
    );
  }

  static Widget _buildKeyBtn(String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0.5,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildIconKeyBtn(
    IconData icon,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
    Color? color,
    Color? bgColor,
  }) {
    return Material(
      color: bgColor ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0.5,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 21, color: color ?? AppTheme.textPrimary),
        ),
      ),
    );
  }

  /// Hộp thoại tổng kết tài chính trước khi hoàn tất và in phiếu
  static Future<bool?> showSessionSummaryDialog({
    required BuildContext context,
    required int totalBags,
    required double netWeightKg,
    required double remainingPayableVnd,
    required double totalGrossWeightKg,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Header
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hoàn tất & Khóa đợt cân?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kiểm tra lại số liệu trước khi chốt và in hóa đơn',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Financial & Metrics Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E8E0)),
                    ),
                    child: Column(
                      children: [
                        _buildMetricRow('Tổng số bao:', '$totalBags bao'),
                        const Divider(height: 16, color: Color(0xFFE8ECE8)),
                        _buildMetricRow(
                          'Tổng kg thô:',
                          '${CurrencyFormatter.formatNumber(totalGrossWeightKg)} kg',
                        ),
                        const Divider(height: 16, color: Color(0xFFE8ECE8)),
                        _buildMetricRow(
                          'Lúa sạch (-bì):',
                          '${CurrencyFormatter.formatNumber(netWeightKg)} kg',
                          isHighlighted: true,
                        ),
                        const Divider(height: 16, color: Color(0xFFE8ECE8)),
                        _buildMetricRow(
                          'Tiền còn lại:',
                          CurrencyFormatter.formatVnd(remainingPayableVnd),
                          color: AppTheme.accent,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: Color(0xFFD6DDD6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Tiếp tục cân'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print_outlined, size: 20),
                          label: const Text('Xác nhận & In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
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
  }


  static Widget _buildMetricRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: (isBold || isHighlighted) ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isHighlighted ? AppTheme.primary : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Hộp thoại xác nhận xóa với màu sắc cảnh báo chuẩn
  static Future<bool?> showDeleteConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Xóa vĩnh viễn',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red Danger Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: Color(0xFFD6DDD6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy bỏ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(confirmLabel),
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
  }

  /// Hộp thoại sao lưu dữ liệu sổ cân an toàn
  static Future<void> showBackupDialog({
    required BuildContext context,
    required int totalSessions,
    required int totalBags,
    required double totalNetKg,
    required double totalAmount,
    required VoidCallback onDownloadFile,
    required VoidCallback onCopyJson,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sao Lưu Sổ Cân',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'An toàn 100% dữ liệu không lo mất máy',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E7E0)),
                    ),
                    child: Column(
                      children: [
                        _buildMetricRow('Số phiên cân:', '$totalSessions phiên'),
                        const SizedBox(height: 6),
                        _buildMetricRow('Tổng số bao:', '$totalBags bao'),
                        const SizedBox(height: 6),
                        _buildMetricRow(
                          'Tổng sản lượng:',
                          '${CurrencyFormatter.formatWeight(totalNetKg)} (${(totalNetKg / 1000).toStringAsFixed(2)} tấn)',
                        ),
                        const SizedBox(height: 6),
                        _buildMetricRow(
                          'Tổng giá trị:',
                          CurrencyFormatter.formatVnd(totalAmount),
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      'Tải tệp sao lưu (.json) / Gửi Zalo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDownloadFile();
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text(
                      'Sao chép mã vào bộ nhớ tạm',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onCopyJson();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hộp thoại phục hồi dữ liệu sổ cân từ nội dung sao lưu
  static Future<Map<String, dynamic>?> showRestoreDialog({
    required BuildContext context,
  }) {
    final textController = TextEditingController();
    bool replaceMode = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.settings_backup_restore_rounded,
                              color: AppTheme.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phục Hồi Sổ Cân',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Khôi phục lại phiên cân từ bản sao lưu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nội dung tệp (.json):',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.paste_rounded, size: 16),
                            label: const Text(
                              'Dán từ bộ nhớ',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (data != null &&
                                  data.text != null &&
                                  data.text!.isNotEmpty) {
                                textController.text = data.text!;
                                setDialogState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: textController,
                        maxLines: 4,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'Dán mã JSON sao lưu vào đây...',
                          hintStyle: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAF8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFD6DDD6)),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 14),
                      // Mode Selector
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: replaceMode,
                              activeColor: AppTheme.primary,
                              onChanged: (val) {
                                setDialogState(() {
                                  replaceMode = val ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Ghi đè toàn bộ sổ cân hiện tại (Nếu không tích, hệ thống sẽ gộp thêm vào)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side:
                                    const BorderSide(color: Color(0xFFD6DDD6)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, null),
                              child: const Text('Hủy bỏ'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 1,
                              ),
                              onPressed: textController.text.trim().isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(ctx, {
                                        'content': textController.text.trim(),
                                        'replace': replaceMode,
                                      });
                                    },
                              child: const Text(
                                'Bắt đầu phục hồi',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
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
      },
    );
  }

  /// Hộp thoại cài đặt giọng đọc TTS dạng Modal Bottom Sheet chuẩn iOS hiện đại
  /// Cho phép tùy chỉnh bật/tắt, tốc độ đọc tự nhiên (0.95x - 1.35x),
  /// kiểu câu đọc (Đầy đủ, Rút gọn, Chỉ số cân), và bấm nghe thử trực tiếp.
  static Future<Map<String, dynamic>?> showTtsSettingsDialog({
    required BuildContext context,
    required bool initialEnabled,
    required VoiceReaderSpeed initialSpeed,
    required VoiceReaderStyle initialStyle,
    required TtsVoiceService ttsService,
  }) {
    bool enabled = initialEnabled;
    VoiceReaderSpeed currentSpeed = initialSpeed;
    VoiceReaderStyle currentStyle = initialStyle;
    bool isTesting = false;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh gạt Modal Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6DDD6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: enabled
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            enabled ? Icons.volume_up : Icons.volume_off,
                            color: enabled
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Cài đặt giọng đọc cân lúa',
                                style: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tối ưu tốc độ nói tự nhiên và phong cách đọc',
                                style: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppTheme.textSecondary,
                          onPressed: () => Navigator.pop(sheetCtx, null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE8EDE8)),
                    const SizedBox(height: 16),

                    // Công tắc Bật / Tắt giọng đọc
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: enabled
                            ? const Color(0xFFF1F8F1)
                            : const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: enabled
                              ? const Color(0xFFA5D6A7)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enabled
                                      ? 'Giọng đọc đang hoạt động'
                                      : 'Đang tắt giọng đọc (Im lặng)',
                                  style: TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: enabled
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  enabled
                                      ? 'Tự động đọc số cân mỗi khi xác nhận bao'
                                      : 'Chỉ hiển thị trên màn hình, không phát âm',
                                  style: const TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: enabled,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              setSheetState(() {
                                enabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phần chọn Tốc độ đọc
                    const Text(
                      'Tốc độ đọc giọng nói',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...VoiceReaderSpeed.values.map((s) {
                      final isSelected = currentSpeed == s;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setSheetState(() {
                              currentSpeed = s;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF1F8F1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFE0E0E0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.label,
                                        style: TextStyle(
                                          fontFamily: 'Be Vietnam Pro',
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        s.description,
                                        style: const TextStyle(
                                          fontFamily: 'Be Vietnam Pro',
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Phần chọn Kiểu câu đọc
                    const Text(
                      'Kiểu câu đọc cân lúa',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...VoiceReaderStyle.values.map((st) {
                      final isSelected = currentStyle == st;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setSheetState(() {
                              currentStyle = st;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF1F8F1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFE0E0E0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        st.label,
                                        style: TextStyle(
                                          fontFamily: 'Be Vietnam Pro',
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Ví dụ: ${st.example}',
                                        style: const TextStyle(
                                          fontFamily: 'Be Vietnam Pro',
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Nút Nghe thử mẫu giọng
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          isTesting ? Icons.hourglass_top : Icons.play_arrow,
                          size: 20,
                        ),
                        label: Text(
                          isTesting
                              ? 'Đang phát âm thanh...'
                              : 'Nghe thử mẫu giọng với cài đặt này',
                          style: const TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: isTesting
                            ? null
                            : () async {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  isTesting = true;
                                });
                                // Áp dụng cấu hình tạm thời để thử
                                await ttsService.setSpeed(currentSpeed);
                                await ttsService.setStyle(currentStyle);
                                final prevEnabled = ttsService.isEnabled;
                                ttsService.isEnabled = true;
                                await ttsService.previewSampleSpeech(
                                  sampleBag: 12,
                                  sampleWeight: 52.5,
                                );
                                ttsService.isEnabled = prevEnabled;

                                if (sheetCtx.mounted) {
                                  setSheetState(() {
                                    isTesting = false;
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hai nút hành động dưới cùng
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(
                                color: Color(0xFFD6DDD6),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(sheetCtx, null),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(sheetCtx, {
                                'enabled': enabled,
                                'speed': currentSpeed,
                                'style': currentStyle,
                              });
                            },
                            child: const Text(
                              'Lưu cấu hình',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


