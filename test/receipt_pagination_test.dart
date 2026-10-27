import 'package:flutter_test/flutter_test.dart';
import 'package:can_lua_app/core/enums/can_lua_enums.dart';
import 'package:can_lua_app/features/weighing/models/bag_weight.dart';
import 'package:can_lua_app/features/weighing/models/weighing_session.dart';
import 'package:can_lua_app/features/weighing/services/receipt_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptPdfService 1000 Bags Pagination & Print Modes', () {
    late WeighingSession largeSession;

    setUp(() {
      final now = DateTime.now();
      // Tạo danh sách giả lập đúng 1.000 bao lúa (mỗi bao khoảng 50.0 - 51.0 kg)
      final thousandBags = List<BagWeight>.generate(1000, (i) {
        return BagWeight(
          index: i + 1,
          grossWeight: 50.0 + ((i % 5) * 0.2), // 50.0, 50.2, 50.4, 50.6, 50.8 kg
          recordedAt: now,
        );
      });

      largeSession = WeighingSession(
        id: 'session-1000-bags',
        sessionCode: 'CL-GHE-1000',
        farmerName: 'Chủ Lúa Út Tịch',
        traderName: 'Ghe Thương Hồ Sông Hậu',
        phoneNumber: '0912345678',
        riceVariety: RiceVariety.daiThom8,
        pricePerKg: 8500.0,
        tarePerBagKg: 0.2,
        depositAmount: 10000000.0,
        groupingMode: WeighingGroupingMode.groupedBatch,
        bagsPerGroup: 5,
        groupsPerBatch: 5, // 25 bao / đợt chốt = 40 đợt chốt tiền
        createdAt: now,
        completedAt: now,
        bags: thousandBags,
      );
    });

    test('Tạo thành công 1.000 bao lúa: Tổng số bao = 1000, 40 đợt chốt tiền', () {
      expect(largeSession.totalBags, 1000);
      final batches = largeSession.getBatches();
      expect(batches.length, 40); // 1000 / 25 = 40 đợt chốt
      expect(largeSession.totalGrossWeight, greaterThan(50000.0)); // > 50 tấn lúa
    });

    test('In khổ A4 chế độ Chi tiết (pw.MultiPage tự động chia đa trang không bị lỗi overflow)', () async {
      final pdfBytes = await ReceiptPdfService.generateReceiptPdf(
        largeSession,
        paperSize: ReceiptPaperSize.standardA4,
        printMode: ReceiptPrintMode.fullDetail,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(10000)); // Tài liệu PDF đa trang hợp lệ
    });

    test('In khổ A4 chế độ Tóm tắt theo đợt (40 đợt chốt tiền)', () async {
      final pdfBytes = await ReceiptPdfService.generateReceiptPdf(
        largeSession,
        paperSize: ReceiptPaperSize.standardA4,
        printMode: ReceiptPrintMode.batchSummary,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('In máy in nhiệt K80 chế độ Tóm tắt theo đợt (Siêu gọn cho cuộn giấy)', () async {
      final pdfBytes = await ReceiptPdfService.generateReceiptPdf(
        largeSession,
        paperSize: ReceiptPaperSize.thermal80mm,
        printMode: ReceiptPrintMode.batchSummary,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('In máy in nhiệt K58 chế độ Tóm tắt theo đợt', () async {
      final pdfBytes = await ReceiptPdfService.generateReceiptPdf(
        largeSession,
        paperSize: ReceiptPaperSize.thermal58mm,
        printMode: ReceiptPrintMode.batchSummary,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
