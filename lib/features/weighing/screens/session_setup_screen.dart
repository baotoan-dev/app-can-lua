import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_responsive_frame.dart';
import '../../../core/widgets/app_segmented_tab.dart';
import '../models/weighing_session.dart';

class SessionSetupScreen extends StatefulWidget {
  final WeighingSession? initialSession;
  final double defaultTare;
  final double defaultPrice;

  const SessionSetupScreen({
    super.key,
    this.initialSession,
    this.defaultTare = 0.2,
    this.defaultPrice = 8200.0,
  });

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _farmerController;
  late TextEditingController _traderController;
  late TextEditingController _phoneController;
  late TextEditingController _priceController;
  late TextEditingController _tareController;
  late TextEditingController _depositController;
  late TextEditingController _noteController;
  late TextEditingController _bagsPerGroupController;
  late TextEditingController _groupsPerBatchController;

  late RiceVariety _selectedVariety;
  late WeighingGroupingMode _groupingMode;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSession;
    _farmerController = TextEditingController(text: s?.farmerName ?? '');
    _traderController = TextEditingController(text: s?.traderName ?? '');
    _phoneController = TextEditingController(text: s?.phoneNumber ?? '');
    _priceController = TextEditingController(
      text: (s?.pricePerKg ?? widget.defaultPrice).toStringAsFixed(0),
    );
    _tareController = TextEditingController(
      text: (s?.tarePerBagKg ?? widget.defaultTare).toString(),
    );
    _depositController = TextEditingController(
      text: s?.depositAmount != null && s!.depositAmount > 0
          ? s.depositAmount.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController(text: s?.note ?? '');
    _selectedVariety = s?.riceVariety ?? RiceVariety.om5451;
    _groupingMode = s?.groupingMode ?? WeighingGroupingMode.groupedBatch;
    _bagsPerGroupController = TextEditingController(
      text: (s?.bagsPerGroup ?? 5).toString(),
    );
    _groupsPerBatchController = TextEditingController(
      text: (s?.groupsPerBatch ?? 5).toString(),
    );
  }

  @override
  void dispose() {
    _farmerController.dispose();
    _traderController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _tareController.dispose();
    _depositController.dispose();
    _noteController.dispose();
    _bagsPerGroupController.dispose();
    _groupsPerBatchController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.replaceAll('.', '').trim()) ?? 8000.0;
    final tare = double.tryParse(_tareController.text.replaceAll(',', '.').trim()) ?? 0.2;
    final deposit = double.tryParse(_depositController.text.replaceAll('.', '').trim()) ?? 0.0;
    final bagsPerGroup = int.tryParse(_bagsPerGroupController.text.trim()) ?? 5;
    final groupsPerBatch = int.tryParse(_groupsPerBatchController.text.trim()) ?? 5;

    final now = DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(now);
    final sessionCode = widget.initialSession?.sessionCode ?? 'CL-$datePrefix-${now.minute}${now.second}';

    final session = (widget.initialSession ??
            WeighingSession(
              id: const Uuid().v4(),
              sessionCode: sessionCode,
              farmerName: _farmerController.text.trim(),
              createdAt: now,
            ))
        .copyWith(
      farmerName: _farmerController.text.trim(),
      traderName: _traderController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      riceVariety: _selectedVariety,
      pricePerKg: price,
      tarePerBagKg: tare,
      depositAmount: deposit,
      note: _noteController.text.trim(),
      groupingMode: _groupingMode,
      bagsPerGroup: bagsPerGroup > 0 ? bagsPerGroup : 5,
      groupsPerBatch: groupsPerBatch >= 0 ? groupsPerBatch : 5,
    );

    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSession != null;

    return AppResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa thông tin' : 'Tạo phiên cân mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Farmer info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('THÔNG TIN CHỦ RUỘNG & ĐỐI TÁC'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _farmerController,
                      decoration: InputDecoration(
                        labelText: 'Tên chủ ruộng / Chủ lúa (*)',
                        hintText: 'Ví dụ: Chú 5 Ruộng, Anh Ba...',
                        prefixIcon: _buildPrefixIcon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên chủ ruộng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: _buildPrefixIcon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _traderController,
                      decoration: InputDecoration(
                        labelText: 'Tên người cân / Thương lái',
                        prefixIcon: _buildPrefixIcon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Rice specification & Pricing card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('GIỐNG LÚA & ĐƠN GIÁ THỎA THUẬN'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RiceVariety>(
                      initialValue: _selectedVariety,
                      decoration: InputDecoration(
                        labelText: 'Giống lúa',
                        prefixIcon: _buildPrefixIcon(Icons.grass_outlined),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      items: RiceVariety.values.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            v.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedVariety = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Đơn giá (đ/kg)',
                              hintText: '8200',
                              suffixIcon: _buildSuffixBadge('VNĐ/kg'),
                              prefixIcon: _buildPrefixIcon(Icons.sell_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nhập đơn giá';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _tareController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Trừ bì',
                              hintText: '0.2',
                              suffixIcon: _buildSuffixBadge('kg'),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nhập bì';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    // Quick Tare Presets
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        children: [
                          const Text(
                            'Bì nhanh:',
                            style: TextStyle(
                              fontFamily: 'Be Vietnam Pro',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...['0.1', '0.2', '0.3', '0.5'].map((tare) {
                            final isSelected = _tareController.text == tare;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _tareController.text = tare;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : const Color(0xFFF1F5F1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : const Color(0xFFD6DDD6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '$tare kg',
                                    style: TextStyle(
                                      fontFamily: 'Be Vietnam Pro',
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _depositController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tiền đã đặt cọc trước (nếu có)',
                        hintText: 'Ví dụ: 10000000',
                        suffixIcon: _buildSuffixBadge('VNĐ'),
                        prefixIcon: _buildPrefixIcon(Icons.payments_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Grouping & Batching configuration card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('CẤU HÌNH PHÂN NHÓM & ĐỢT CHỐT TIỀN'),
                    const SizedBox(height: 16),
                    AppSegmentedTab<WeighingGroupingMode>(
                      height: 44,
                      selectedValue: _groupingMode,
                      onTabChanged: (val) {
                        setState(() => _groupingMode = val);
                      },
                      items: const [
                        AppTabItem(
                          value: WeighingGroupingMode.groupedBatch,
                          label: 'Phân nhóm & Đợt chốt',
                        ),
                        AppTabItem(
                          value: WeighingGroupingMode.continuous,
                          label: 'Cân liên tục',
                        ),
                      ],
                    ),
                    if (_groupingMode == WeighingGroupingMode.groupedBatch) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bagsPerGroupController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Số bao / 1 nhóm',
                                hintText: '5',
                                helperText: 'Thường là 5 bao',
                                suffixIcon: _buildSuffixBadge('bao'),
                              ),
                              validator: (val) {
                                final n = int.tryParse(val ?? '');
                                if (n == null || n <= 0) {
                                  return 'Nhập số bao';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _groupsPerBatchController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Số nhóm / 1 đợt',
                                hintText: '5',
                                helperText: '5 nhóm = 25 bao',
                                suffixIcon: _buildSuffixBadge('nhóm'),
                              ),
                              validator: (val) {
                                final n = int.tryParse(val ?? '');
                                if (n == null || n < 0) {
                                  return 'Nhập số nhóm';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC8E6C9),
                          ),
                        ),
                        child: Text(
                          'Cấu hình: Cứ mỗi ${_bagsPerGroupController.text} bao gom thành 1 nhóm tính tổng; '
                          'đủ ${_groupsPerBatchController.text} nhóm (khoảng ${(int.tryParse(_bagsPerGroupController.text) ?? 5) * (int.tryParse(_groupsPerBatchController.text) ?? 5)} bao) '
                          'hệ thống sẽ tự chốt tổng tiền của đợt đó.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Note card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('GHI CHÚ HIỆN TRƯỜNG'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Số xe, chủ ghe, chất lượng lúa, địa điểm ruộng...',
                        prefixIcon: _buildPrefixIcon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEditing ? Icons.save_outlined : Icons.play_arrow_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'LƯU THAY ĐỔI' : 'BẮT ĐẦU CÂN LÚA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPrefixIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: AppTheme.primary),
    );
  }

  Widget _buildSuffixBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
