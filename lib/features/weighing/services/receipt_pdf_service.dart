import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/bag_weight.dart';
import '../models/weighing_session.dart';

class ReceiptPdfService {
  ReceiptPdfService._();

  static Future<Uint8List> generateReceiptPdf(
    WeighingSession session, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.thermal80mm,
    ReceiptPrintMode printMode = ReceiptPrintMode.fullDetail,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final PdfPageFormat format;
    final double fontSizeBase;
    final int columnsPerRow;

    switch (paperSize) {
      case ReceiptPaperSize.thermal58mm:
        format = const PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 2 * PdfPageFormat.mm,
        );
        fontSizeBase = 7.5;
        columnsPerRow = 4;
        break;
      case ReceiptPaperSize.thermal80mm:
        format = const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 3 * PdfPageFormat.mm,
        );
        fontSizeBase = 8.5;
        columnsPerRow = 5;
        break;
      case ReceiptPaperSize.standardA4:
        format = PdfPageFormat.a4.copyWith(
          marginTop: 15 * PdfPageFormat.mm,
          marginBottom: 15 * PdfPageFormat.mm,
          marginLeft: 15 * PdfPageFormat.mm,
          marginRight: 15 * PdfPageFormat.mm,
        );
        fontSizeBase = 10.0;
        columnsPerRow = 10;
        break;
    }

    final dateStr = DateFormat('dd/MM/yyyy HH:mm')
        .format(session.completedAt ?? session.createdAt);

    if (paperSize == ReceiptPaperSize.standardA4) {
      // Khổ A4: Sử dụng MultiPage để tự động chia trang mượt mà (hỗ trợ 1.000+ bao không bị overflow)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          theme: theme,
          header: (pw.Context context) {
            return _buildA4Header(session, context, fontSizeBase);
          },
          footer: (pw.Context context) {
            return _buildA4Footer(context, fontSizeBase);
          },
          build: (pw.Context context) {
            return [
              _buildTitleSection(session, fontSizeBase, dateStr),
              _buildPartiesInfoSection(session, fontSizeBase),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    printMode == ReceiptPrintMode.batchSummary
                        ? 'BẢNG TỔNG HỢP CÁC ĐỢT CÂN (${session.totalBags} bao):'
                        : 'CHI TIẾT CÁC MÃ CÂN (${session.totalBags} bao):',
                    style: pw.TextStyle(
                      fontSize: fontSizeBase,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (printMode == ReceiptPrintMode.batchSummary)
                    pw.Text(
                      '(Chế độ tóm tắt theo đợt)',
                      style: pw.TextStyle(
                        fontSize: fontSizeBase - 2,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 4),
              if (printMode == ReceiptPrintMode.batchSummary)
                ..._buildBatchSummaryWidgets(session, fontSizeBase)
              else
                ..._buildMatrixTables(session, columnsPerRow, fontSizeBase),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              _buildCalculationSummary(session, fontSizeBase),
              pw.SizedBox(height: 12),
              _buildSignatures(fontSizeBase),
            ];
          },
        ),
      );
    } else {
      // Khổ giấy in nhiệt cuộn (58mm / 80mm): In dải giấy liên tục
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          theme: theme,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildTitleSection(session, fontSizeBase, dateStr),
                _buildPartiesInfoSection(session, fontSizeBase),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.Text(
                  printMode == ReceiptPrintMode.batchSummary
                      ? 'TỔNG HỢP CÁC ĐỢT CÂN (${session.totalBags} bao):'
                      : 'CHI TIẾT CÁC MÃ CÂN (${session.totalBags} bao):',
                  style: pw.TextStyle(
                    fontSize: fontSizeBase,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (printMode == ReceiptPrintMode.batchSummary)
                  ..._buildBatchSummaryWidgets(session, fontSizeBase)
                else
                  ..._buildMatrixTables(session, columnsPerRow, fontSizeBase),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                _buildCalculationSummary(session, fontSizeBase),
                pw.SizedBox(height: 10),
                _buildSignatures(fontSizeBase),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Cảm ơn quý khách - Cân Lúa Offline',
                    style: pw.TextStyle(
                      fontSize: fontSizeBase - 2,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildA4Header(
    WeighingSession session,
    pw.Context context,
    double fontSizeBase,
  ) {
    if (context.pageNumber > 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey500),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Phiếu cân: ${session.sessionCode} - Chủ ruộng: ${session.farmerName}',
              style: pw.TextStyle(
                fontSize: fontSizeBase - 1,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.Text(
              'Trang ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: fontSizeBase - 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return pw.SizedBox.shrink();
  }

  static pw.Widget _buildA4Footer(pw.Context context, double fontSizeBase) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Phần mềm Cân Lúa Nông Sản - Offline First',
            style: pw.TextStyle(
              fontSize: fontSizeBase - 2,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: fontSizeBase - 2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleSection(
    WeighingSession session,
    double fontSizeBase,
    String dateStr,
  ) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'PHIẾU CÂN LÚA NÔNG SẢN',
            style: pw.TextStyle(
              fontSize: fontSizeBase + 3,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'Mã phiếu: ${session.sessionCode}',
            style: pw.TextStyle(
              fontSize: fontSizeBase,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Ngày: $dateStr',
            style: pw.TextStyle(fontSize: fontSizeBase - 1),
          ),
        ),
        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
      ],
    );
  }

  static pw.Widget _buildPartiesInfoSection(
    WeighingSession session,
    double fontSizeBase,
  ) {
    return pw.Column(
      children: [
        _buildInfoRow('Chủ ruộng:', session.farmerName, fontSizeBase),
        if (session.phoneNumber.isNotEmpty)
          _buildInfoRow('Điện thoại:', session.phoneNumber, fontSizeBase),
        if (session.traderName.isNotEmpty)
          _buildInfoRow('Người cân / Thương lái:', session.traderName, fontSizeBase),
        _buildInfoRow('Giống lúa:', session.riceVariety.displayName, fontSizeBase),
        _buildInfoRow('Đơn giá:', CurrencyFormatter.formatVnd(session.pricePerKg), fontSizeBase),
        _buildInfoRow('Trừ bì bao:', '${session.tarePerBagKg} kg/bao', fontSizeBase),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCalculationSummary(
    WeighingSession session,
    double fontSizeBase,
  ) {
    return pw.Column(
      children: [
        _buildSummaryRow(
          'Tổng số bao:',
          '${session.totalBags} bao',
          fontSizeBase,
          bold: true,
        ),
        _buildSummaryRow(
          'Tổng kg thô:',
          CurrencyFormatter.formatWeight(session.totalGrossWeight),
          fontSizeBase,
        ),
        _buildSummaryRow(
          'Trừ bì (${session.totalBags} x ${session.tarePerBagKg}kg):',
          '- ${CurrencyFormatter.formatWeight(session.totalTareWeight)}',
          fontSizeBase,
        ),
        pw.Divider(thickness: 0.5),
        _buildSummaryRow(
          'KHỐI LƯỢNG SẠCH:',
          CurrencyFormatter.formatWeight(session.netWeight),
          fontSizeBase + 1,
          bold: true,
        ),
        _buildSummaryRow(
          'Thành tiền:',
          CurrencyFormatter.formatVnd(session.totalAmount),
          fontSizeBase + 1,
          bold: true,
        ),
        if (session.depositAmount > 0) ...[
          _buildSummaryRow(
            'Trừ tiền đã cọc:',
            '- ${CurrencyFormatter.formatVnd(session.depositAmount)}',
            fontSizeBase,
          ),
        ],
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: _buildSummaryRow(
            'CÒN LẠI PHẢI TRẢ:',
            CurrencyFormatter.formatVnd(session.remainingPayable),
            fontSizeBase + 2,
            bold: true,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value,
    double fontSize, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures(double fontSizeBase) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.Text(
              'CHỦ RUỘNG',
              style: pw.TextStyle(
                fontSize: fontSizeBase,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Text(
              '(Ký và ghi rõ họ tên)',
              style: pw.TextStyle(fontSize: fontSizeBase - 2),
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Text(
              'NGƯỜI CÂN',
              style: pw.TextStyle(
                fontSize: fontSizeBase,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Text(
              '(Ký và ghi rõ họ tên)',
              style: pw.TextStyle(fontSize: fontSizeBase - 2),
            ),
          ],
        ),
      ],
    );
  }

  /// Tóm tắt các đợt cân (Batch Summary) - Dành riêng cho đơn hàng lớn 1.000 bao
  static List<pw.Widget> _buildBatchSummaryWidgets(
    WeighingSession session,
    double fontSize,
  ) {
    if (session.groupingMode == WeighingGroupingMode.groupedBatch) {
      return _buildGroupedBatchSummaryWidgets(session, fontSize);
    }
    return _buildContinuousSummaryWidgets(session, fontSize);
  }

  static List<pw.Widget> _buildGroupedBatchSummaryWidgets(
    WeighingSession session,
    double fontSize,
  ) {
    final List<pw.Widget> widgets = [];
    final batches = session.getBatches();

    // Table Header
    widgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 2, bottom: 2),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'ĐỢT CÂN',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'SỐ BAO',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'TỔNG THÔ',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'LÚA SẠCH',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'THÀNH TIỀN',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );

    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final isZebra = i % 2 == 1;

      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          decoration: pw.BoxDecoration(
            color: isZebra ? PdfColors.grey100 : PdfColors.white,
            border: const pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Đợt ${batch.batchIndex}',
                  style: pw.TextStyle(fontSize: fontSize - 1.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '${batch.totalBags} bao',
                  style: pw.TextStyle(fontSize: fontSize - 1.5),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  CurrencyFormatter.formatWeight(batch.grossWeight),
                  style: pw.TextStyle(fontSize: fontSize - 1.5),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  CurrencyFormatter.formatWeight(batch.netWeight),
                  style: pw.TextStyle(fontSize: fontSize - 1.5, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  CurrencyFormatter.formatVnd(batch.amount),
                  style: pw.TextStyle(fontSize: fontSize - 1.5, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _buildContinuousSummaryWidgets(
    WeighingSession session,
    double fontSize,
  ) {
    final List<pw.Widget> widgets = [];
    final rows = session.getMatrixRows(columns: 20);

    widgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 2, bottom: 2),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'MÃ NHÓM',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'SỐ BAO',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'TỔNG THÔ',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'THÀNH TIỀN',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );

    for (int i = 0; i < rows.length; i++) {
      final chunk = rows[i];
      final gross = chunk.fold(0.0, (sum, b) => sum + b.grossWeight);
      final net = gross - (chunk.length * session.tarePerBagKg);
      final amount = net * session.pricePerKg;
      final isZebra = i % 2 == 1;

      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          decoration: pw.BoxDecoration(
            color: isZebra ? PdfColors.grey100 : PdfColors.white,
            border: const pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Bao ${i * 20 + 1} - ${i * 20 + chunk.length}',
                  style: pw.TextStyle(fontSize: fontSize - 1.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '${chunk.length} bao',
                  style: pw.TextStyle(fontSize: fontSize - 1.5),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  CurrencyFormatter.formatWeight(gross),
                  style: pw.TextStyle(fontSize: fontSize - 1.5),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  CurrencyFormatter.formatVnd(amount),
                  style: pw.TextStyle(fontSize: fontSize - 1.5, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _buildMatrixTables(
    WeighingSession session,
    int columnsPerRow,
    double fontSize,
  ) {
    if (session.groupingMode == WeighingGroupingMode.groupedBatch) {
      return _buildBatchWidgets(session, fontSize);
    }
    return _buildContinuousWidgets(session, columnsPerRow, fontSize);
  }

  static List<pw.Widget> _buildBatchWidgets(WeighingSession session, double fontSize) {
    final batches = session.getBatches();
    final targetCols = session.bagsPerGroup > 0 ? session.bagsPerGroup : 5;
    final List<pw.Widget> widgets = [];

    for (final batch in batches) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: PdfColors.grey200,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ĐỢT ${batch.batchIndex} (${batch.totalBags} bao)',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Thô: ${CurrencyFormatter.formatWeight(batch.grossWeight)}',
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      );

      for (final group in batch.groups) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
            child: pw.Row(
              children: [
                ..._buildFixedCells(group.bags, targetCols, fontSize),
                pw.Container(
                  width: 32,
                  padding: const pw.EdgeInsets.only(left: 3),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    CurrencyFormatter.formatNumber(group.grossWeight),
                    style: pw.TextStyle(fontSize: fontSize - 2, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 3),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          color: PdfColors.grey100,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Tổng tiền Đợt ${batch.batchIndex} (${batch.totalBags} bao):',
                style: pw.TextStyle(fontSize: fontSize - 2, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                CurrencyFormatter.formatVnd(batch.amount),
                style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _buildContinuousWidgets(
    WeighingSession session,
    int columnsPerRow,
    double fontSize,
  ) {
    final rows = session.getMatrixRows(columns: columnsPerRow);
    final List<pw.Widget> widgets = [];

    for (int r = 0; r < rows.length; r++) {
      final rowBags = rows[r];
      final rowSubtotal = rowBags.fold(0.0, (sum, b) => sum + b.grossWeight);

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
          child: pw.Row(
            children: [
              ..._buildFixedCells(rowBags, columnsPerRow, fontSize),
              pw.Container(
                width: 36,
                padding: const pw.EdgeInsets.only(left: 3),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  CurrencyFormatter.formatNumber(rowSubtotal),
                  style: pw.TextStyle(fontSize: fontSize - 2, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _buildFixedCells(
    List<BagWeight> bags,
    int targetCols,
    double fontSize,
  ) {
    return List<pw.Widget>.generate(targetCols, (colIndex) {
      if (colIndex < bags.length) {
        final bag = bags[colIndex];
        return pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '#${bag.index}',
                  style: pw.TextStyle(fontSize: fontSize - 2.5, color: PdfColors.grey700),
                ),
                pw.Text(
                  CurrencyFormatter.formatNumber(bag.grossWeight),
                  style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
          ),
          child: pw.SizedBox(height: fontSize * 2),
        ),
      );
    });
  }

  static Future<void> printReceipt(
    WeighingSession session, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.thermal80mm,
    ReceiptPrintMode printMode = ReceiptPrintMode.fullDetail,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      session,
      paperSize: paperSize,
      printMode: printMode,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Phieu_Can_${session.sessionCode}',
    );
  }

  static Future<void> shareReceipt(
    WeighingSession session, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.thermal80mm,
    ReceiptPrintMode printMode = ReceiptPrintMode.fullDetail,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      session,
      paperSize: paperSize,
      printMode: printMode,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Phieu_Can_${session.sessionCode}.pdf',
    );
  }
}
