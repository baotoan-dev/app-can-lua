import 'package:flutter_test/flutter_test.dart';
import 'package:can_lua_app/core/enums/can_lua_enums.dart';
import 'package:can_lua_app/features/weighing/models/bag_weight.dart';
import 'package:can_lua_app/features/weighing/models/weighing_session.dart';

void main() {
  group('WeighingSession Calculations (Công thức tính toán)', () {
    test('Tính đúng tổng kg thô, trừ bì, lúa sạch, thành tiền và tiền còn lại', () {
      final now = DateTime.now();
      final bags = [
        BagWeight(index: 1, grossWeight: 50.0, recordedAt: now),
        BagWeight(index: 2, grossWeight: 52.5, recordedAt: now),
        BagWeight(index: 3, grossWeight: 49.5, recordedAt: now),
        BagWeight(index: 4, grossWeight: 51.0, recordedAt: now),
        BagWeight(index: 5, grossWeight: 50.5, recordedAt: now),
      ];

      final session = WeighingSession(
        id: 'test-1',
        sessionCode: 'CL-TEST',
        farmerName: 'Chú Ba Ruộng',
        riceVariety: RiceVariety.om5451,
        pricePerKg: 8000.0,
        tarePerBagKg: 0.2,
        depositAmount: 500000.0,
        createdAt: now,
        bags: bags,
      );

      // Tổng số bao = 5
      expect(session.totalBags, 5);

      // Tổng kg thô = 50.0 + 52.5 + 49.5 + 51.0 + 50.5 = 253.5 kg
      expect(session.totalGrossWeight, 253.5);

      // Tổng trừ bì = 5 * 0.2 = 1.0 kg
      expect(session.totalTareWeight, 1.0);

      // Lúa sạch = 253.5 - 1.0 = 252.5 kg
      expect(session.netWeight, 252.5);

      // Tổng thành tiền = 252.5 * 8000 = 2,020,000 VNĐ
      expect(session.totalAmount, 2020000.0);

      // Còn lại phải trả = 2,020,000 - 500,000 = 1,520,000 VNĐ
      expect(session.remainingPayable, 1520000.0);

      // Trọng lượng trung bình = 253.5 / 5 = 50.7 kg
      expect(session.averageBagWeight, closeTo(50.7, 0.001));
    });

    test('Phân nhóm 5 bao/nhóm và đợt chốt 5 nhóm (25 bao) tính tiền chính xác', () {
      final now = DateTime.now();
      // Tạo 27 bao: mỗi bao 50.0 kg, giá 8.000 d/kg, trừ bì 0.2 kg/bao
      // Lúa sạch mỗi bao: 49.8 kg, tiền mỗi bao: 398.400 đ
      final bags = List.generate(
        27,
        (i) => BagWeight(index: i + 1, grossWeight: 50.0, recordedAt: now),
      );

      final session = WeighingSession(
        id: 'test-grouped',
        sessionCode: 'CL-GROUPED',
        farmerName: 'Chú 5 Ruộng',
        riceVariety: RiceVariety.daiThom8,
        pricePerKg: 8000.0,
        tarePerBagKg: 0.2,
        groupingMode: WeighingGroupingMode.groupedBatch,
        bagsPerGroup: 5,
        groupsPerBatch: 5,
        createdAt: now,
        bags: bags,
      );

      // Tổng cộng có 6 nhóm (5 nhóm đủ 5 bao + 1 nhóm 2 bao)
      final groups = session.getGroups();
      expect(groups.length, 6);
      expect(groups[0].totalBags, 5);
      expect(groups[0].grossWeight, 250.0);
      expect(groups[0].tareWeight, 1.0);
      expect(groups[0].netWeight, 249.0);
      expect(groups[0].amount, 249.0 * 8000); // 1.992.000 đ
      expect(groups[5].totalBags, 2);

      // Tổng cộng có 2 đợt chốt (Batch 1: 5 nhóm = 25 bao; Batch 2: 1 nhóm = 2 bao)
      final batches = session.getBatches();
      expect(batches.length, 2);

      // Đợt 1 (Đợt lớn 25 bao):
      final batch1 = batches[0];
      expect(batch1.batchIndex, 1);
      expect(batch1.totalBags, 25);
      expect(batch1.grossWeight, 25 * 50.0); // 1.250 kg
      expect(batch1.tareWeight, 25 * 0.2);   // 5 kg
      expect(batch1.netWeight, 1245.0);      // 1.245 kg sạch
      expect(batch1.amount, 1245.0 * 8000);  // 9.960.000 đ
      expect(batch1.isFull, true);

      // Đợt 2:
      final batch2 = batches[1];
      expect(batch2.batchIndex, 2);
      expect(batch2.totalBags, 2);
      expect(batch2.grossWeight, 100.0);
      expect(batch2.tareWeight, 0.4);
      expect(batch2.netWeight, 99.6);
      expect(batch2.amount, 99.6 * 8000); // 796.800 đ
      expect(batch2.isFull, false);

      // Tổng tiền của 2 đợt chốt phải bằng chính xác tổng tiền của cả phiên cân
      expect(batch1.amount + batch2.amount, session.totalAmount);
    });

    test('Lưu và khôi phục JSON giữ nguyên groupingMode, bagsPerGroup và groupsPerBatch', () {
      final now = DateTime.now();
      final original = WeighingSession(
        id: 'sess-json-02',
        sessionCode: 'CL-20261027-100',
        farmerName: 'Bác Năm',
        traderName: 'Luận Thiều',
        riceVariety: RiceVariety.st25,
        pricePerKg: 10500.0,
        tarePerBagKg: 0.3,
        depositAmount: 2000000.0,
        groupingMode: WeighingGroupingMode.groupedBatch,
        bagsPerGroup: 5,
        groupsPerBatch: 5,
        status: WeighingSessionStatus.completed,
        createdAt: now,
        bags: [
          BagWeight(index: 1, grossWeight: 54.5, recordedAt: now),
        ],
      );

      final json = original.toJson();
      final restored = WeighingSession.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.groupingMode, WeighingGroupingMode.groupedBatch);
      expect(restored.bagsPerGroup, 5);
      expect(restored.groupsPerBatch, 5);
      expect(restored.totalBags, 1);
    });
  });
}
