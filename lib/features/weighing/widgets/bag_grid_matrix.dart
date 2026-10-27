import 'package:flutter/material.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/bag_weight.dart';
import '../models/weighing_group.dart';
import '../models/weighing_session.dart';

class BagGridMatrix extends StatelessWidget {
  final WeighingSession session;
  final int columnsPerRow;
  final ScrollController scrollController;
  final Function(BagWeight bag) onBagTap;

  const BagGridMatrix({
    super.key,
    required this.session,
    this.columnsPerRow = 5,
    required this.scrollController,
    required this.onBagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (session.bags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scale_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có bao lúa nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhập số ký bằng bàn phím bên dưới để bắt đầu',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (session.groupingMode == WeighingGroupingMode.groupedBatch) {
      return _buildGroupedBatchView();
    } else {
      return _buildContinuousView();
    }
  }

  /// Chế độ phân nhóm (5 bao/nhóm) và đợt chốt tiền (5 nhóm = 25 bao/đợt)
  Widget _buildGroupedBatchView() {
    final batches = session.getBatches();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: batches.length,
      itemBuilder: (context, batchIndex) {
        final batch = batches[batchIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header của Đợt (Batch)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.5),
                    topRight: Radius.circular(8.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ĐỢT ${batch.batchIndex}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${batch.groups.length} nhóm (${batch.totalBags} bao)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Thô: ${CurrencyFormatter.formatWeight(batch.grossWeight)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách các Nhóm (Groups) trong đợt này
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: batch.groups.map((group) {
                    return _buildGroupRow(group);
                  }).toList(),
                ),
              ),

              // Footer tổng tiền lớn của Đợt chốt (Batch Summary Banner)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.09),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8.5),
                    bottomRight: Radius.circular(8.5),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG TIỀN ĐỢT ${batch.batchIndex}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Sạch: ${CurrencyFormatter.formatWeight(batch.netWeight)} (-bì ${CurrencyFormatter.formatWeight(batch.tareWeight)})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.formatVnd(batch.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dòng hiển thị 1 Nhóm (ví dụ 5 bao)
  Widget _buildGroupRow(WeighingGroup group) {
    final targetCols = session.bagsPerGroup > 0 ? session.bagsPerGroup : 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nhóm ${group.groupIndex} (${group.bags.length}/$targetCols bao)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Tổng: ${CurrencyFormatter.formatWeight(group.grossWeight)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(targetCols, (colIndex) {
              if (colIndex < group.bags.length) {
                final bag = group.bags[colIndex];
                final isLatest = (bag.index == session.totalBags);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onBagTap(bag),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? const Color(0xFFFFF3E0)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLatest ? AppTheme.accent : const Color(0xFFD6DDD6),
                          width: isLatest ? 1.6 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isLatest ? 0.08 : 0.03),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${bag.index}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isLatest
                                  ? AppTheme.accent
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatNumber(bag.grossWeight),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isLatest
                                  ? AppTheme.accent
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text('-', style: TextStyle(color: Colors.transparent, fontSize: 9)),
                        SizedBox(height: 1),
                        Text('-', style: TextStyle(color: Colors.transparent, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  /// Chế độ liên tục (Continuous View)
  Widget _buildContinuousView() {
    final rows = session.getMatrixRows(columns: columnsPerRow);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: rows.length,
      itemBuilder: (context, rowIndex) {
        final rowBags = rows[rowIndex];
        final rowSubtotal =
            rowBags.fold(0.0, (sum, bag) => sum + bag.grossWeight);
        final maIndex = rowIndex + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hàng $maIndex (${rowBags.length} bao)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Tổng: ${CurrencyFormatter.formatWeight(rowSubtotal)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: List.generate(columnsPerRow, (colIndex) {
                    if (colIndex < rowBags.length) {
                      final bag = rowBags[colIndex];
                      final isLatest = (bag.index == session.totalBags);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onBagTap(bag),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isLatest
                                  ? const Color(0xFFFFF3E0)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLatest ? AppTheme.accent : const Color(0xFFD6DDD6),
                                width: isLatest ? 1.6 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isLatest ? 0.08 : 0.03),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '#${bag.index}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isLatest
                                        ? AppTheme.accent
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.formatNumber(bag.grossWeight),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isLatest
                                        ? AppTheme.accent
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text('-', style: TextStyle(color: Colors.transparent, fontSize: 9)),
                              SizedBox(height: 2),
                              Text('-', style: TextStyle(color: Colors.transparent, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
