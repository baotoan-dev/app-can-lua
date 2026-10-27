import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:can_lua_app/core/theme/app_theme.dart';
import 'package:can_lua_app/core/widgets/app_modal_dialog.dart';

void main() {
  Widget buildTestApp({
    required int bagIndex,
    required double currentWeight,
    double? pricePerKg,
    int? totalBags,
    required Function(Map<String, dynamic>?) onResult,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final res = await AppModalDialog.showEditBagDialog(
                  context: context,
                  bagIndex: bagIndex,
                  currentWeight: currentWeight,
                  pricePerKg: pricePerKg,
                  totalBags: totalBags,
                );
                onResult(res);
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  group('Edit Bag Modal Widget Tests', () {
    testWidgets('Renders bag index, current weight, and steppers', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          bagIndex: 12,
          currentWeight: 58.5,
          pricePerKg: 8200,
          totalBags: 20,
          onResult: (_) {},
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('CHỈNH SỬA BAO #12'), findsOneWidget);
      expect(find.text('58.5'), findsOneWidget);
      expect(find.text('Gốc: 58.5 kg'), findsOneWidget);
      expect(find.text('+0.1'), findsOneWidget);
      expect(find.text('-0.1'), findsOneWidget);
      expect(find.text('+1.0'), findsOneWidget);
      expect(find.text('-1.0'), findsOneWidget);
      expect(find.textContaining('LƯU SỐ CÂN'), findsOneWidget);
    });

    testWidgets('Tapping stepper updates weight and financial diff badge', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          bagIndex: 5,
          currentWeight: 50.0,
          pricePerKg: 8000,
          totalBags: 10,
          onResult: (_) {},
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap +1.0 stepper
      await tester.tap(find.text('+1.0'));
      await tester.pumpAndSettle();

      // Should show 51 and diff text with financial calculation (1.0 kg * 8,000 = +8.000 đ)
      expect(find.text('51'), findsOneWidget);
      expect(find.textContaining('+1.0 kg'), findsOneWidget);
      expect(find.textContaining('8.000'), findsOneWidget);
      expect(find.textContaining('51'), findsWidgets);
    });

    testWidgets('Tapping delete icon switches to confirmation view; Cancel restores edit view', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          bagIndex: 8,
          currentWeight: 62.3,
          totalBags: 15,
          onResult: (_) {},
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Delete icon button in header
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Should now display confirmation view
      expect(find.text('XÁC NHẬN XÓA BAO #8?'), findsOneWidget);
      expect(find.textContaining('Bao số #8 có khối lượng 62.3 kg sẽ bị xóa'), findsOneWidget);
      expect(find.textContaining('từ #9 đến #15'), findsOneWidget);
      expect(find.text('HỦY BỎ'), findsOneWidget);
      expect(find.text('XÓA BAO NÀY'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('HỦY BỎ'));
      await tester.pumpAndSettle();

      // Restores edit view
      expect(find.text('CHỈNH SỬA BAO #8'), findsOneWidget);
      expect(find.text('62.3'), findsOneWidget);
    });

    testWidgets('Confirming delete returns action delete', (tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        buildTestApp(
          bagIndex: 3,
          currentWeight: 55.0,
          totalBags: 5,
          onResult: (res) => result = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Tap Confirm Delete
      await tester.tap(find.text('XÓA BAO NÀY'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['action'], 'delete');
    });

    testWidgets('Saving updated weight returns action update with new weight', (tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        buildTestApp(
          bagIndex: 1,
          currentWeight: 60.0,
          totalBags: 5,
          onResult: (res) => result = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap +0.1 stepper
      await tester.tap(find.text('+0.1'));
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.textContaining('LƯU SỐ CÂN'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['action'], 'update');
      expect(result!['weight'], 60.1);
    });
  });
}
