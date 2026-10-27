import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/enums/can_lua_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_responsive_frame.dart';
import '../../../core/widgets/app_segmented_tab.dart';
import '../models/weighing_session.dart';
import '../services/receipt_pdf_service.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final WeighingSession session;

  const ReceiptPreviewScreen({
    super.key,
    required this.session,
  });

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  ReceiptPaperSize _paperSize = ReceiptPaperSize.thermal80mm;
  ReceiptPrintMode _printMode = ReceiptPrintMode.fullDetail;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Phiếu cân: ${widget.session.sessionCode}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Chia sẻ qua Zalo / File',
              onPressed: () {
                ReceiptPdfService.shareReceipt(
                  widget.session,
                  paperSize: _paperSize,
                  printMode: _printMode,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'In trực tiếp',
              onPressed: () {
                ReceiptPdfService.printReceipt(
                  widget.session,
                  paperSize: _paperSize,
                  printMode: _printMode,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Selectors Bar (Khổ giấy & Kiểu in)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.white,
              child: Column(
                children: [
                  // Paper format row
                  Row(
                    children: [
                      const SizedBox(
                        width: 68,
                        child: Text(
                          'Khổ giấy',
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AppSegmentedTab<ReceiptPaperSize>(
                          height: 38,
                          selectedValue: _paperSize,
                          onTabChanged: (val) {
                            setState(() => _paperSize = val);
                          },
                          items: const [
                            AppTabItem(
                              value: ReceiptPaperSize.thermal80mm,
                              label: 'K80 (80mm)',
                            ),
                            AppTabItem(
                              value: ReceiptPaperSize.thermal58mm,
                              label: 'K58 (58mm)',
                            ),
                            AppTabItem(
                              value: ReceiptPaperSize.standardA4,
                              label: 'A4',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Print mode row (Chi tiết từng bao vs Tóm tắt đợt)
                  Row(
                    children: [
                      const SizedBox(
                        width: 68,
                        child: Text(
                          'Kiểu in',
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AppSegmentedTab<ReceiptPrintMode>(
                          height: 38,
                          selectedValue: _printMode,
                          onTabChanged: (val) {
                            setState(() => _printMode = val);
                          },
                          items: const [
                            AppTabItem(
                              value: ReceiptPrintMode.fullDetail,
                              label: 'Chi tiết từng bao',
                            ),
                            AppTabItem(
                              value: ReceiptPrintMode.batchSummary,
                              label: 'Tóm tắt đợt',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Live PDF Preview
            Expanded(
              child: PdfPreview(
                build: (format) => ReceiptPdfService.generateReceiptPdf(
                  widget.session,
                  paperSize: _paperSize,
                  printMode: _printMode,
                ),
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8E2))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFC8D6C8), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: const Text('Gửi qua Zalo', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () {
                        ReceiptPdfService.shareReceipt(
                          widget.session,
                          paperSize: _paperSize,
                          printMode: _printMode,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 20),
                        label: Text(
                          _paperSize == ReceiptPaperSize.standardA4
                              ? 'In phiếu A4'
                              : 'In phiếu nhiệt',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        onPressed: () {
                          ReceiptPdfService.printReceipt(
                            widget.session,
                            paperSize: _paperSize,
                            printMode: _printMode,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
