import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:can_lua_app/core/theme/app_theme.dart';
import 'package:can_lua_app/core/widgets/app_segmented_tab.dart';

void main() {
  group('AppSegmentedTab Widget Tests', () {
    testWidgets('Renders all tabs and badge counters accurately',
        (tester) async {
      String selected = 'all';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppSegmentedTab<String>(
                  selectedValue: selected,
                  onTabChanged: (val) {
                    setState(() => selected = val);
                  },
                  items: const [
                    AppTabItem(value: 'all', label: 'Tất cả', badgeCount: 15),
                    AppTabItem(value: 'draft', label: 'Đang cân', badgeCount: 3),
                    AppTabItem(
                        value: 'completed', label: 'Hoàn tất', badgeCount: 12),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify labels rendered
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Đang cân'), findsOneWidget);
      expect(find.text('Hoàn tất'), findsOneWidget);

      // Verify badge counters rendered
      expect(find.text('15'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('Triggers onTabChanged callback when tapping inactive tab',
        (tester) async {
      String selected = 'all';
      String? changedTo;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppSegmentedTab<String>(
                  selectedValue: selected,
                  onTabChanged: (val) {
                    changedTo = val;
                    setState(() => selected = val);
                  },
                  items: const [
                    AppTabItem(value: 'all', label: 'Tất cả'),
                    AppTabItem(value: 'draft', label: 'Đang cân'),
                    AppTabItem(value: 'completed', label: 'Hoàn tất'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Tap on 'Đang cân'
      await tester.tap(find.text('Đang cân'));
      await tester.pumpAndSettle();

      expect(changedTo, 'draft');
      expect(selected, 'draft');
    });

    testWidgets('Does not trigger callback when tapping already active tab',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppSegmentedTab<String>(
              selectedValue: 'all',
              onTabChanged: (_) => callCount++,
              items: const [
                AppTabItem(value: 'all', label: 'Tất cả'),
                AppTabItem(value: 'draft', label: 'Đang cân'),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });
  });
}
