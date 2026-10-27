import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Item descriptor for an [AppSegmentedTab] option.
class AppTabItem<T> {
  final T value;
  final String label;
  final int? badgeCount;

  const AppTabItem({
    required this.value,
    required this.label,
    this.badgeCount,
  });
}

/// A modern iOS-style segmented pill tab control.
/// Designed according to UI/UX Pro Max and Zero-Icon Slop standards:
/// - Smooth tactile pill elevation on active state
/// - Elegant muted slate background container
/// - Clean typography without unnecessary decorative icons
/// - Optional badge counters for filtering lists
class AppSegmentedTab<T> extends StatelessWidget {
  final List<AppTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onTabChanged;
  final EdgeInsetsGeometry? margin;
  final double height;
  final bool expanded;

  const AppSegmentedTab({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onTabChanged,
    this.margin,
    this.height = 44.0,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.tabContainerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4DC),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          final tabWidget = InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (!isSelected) {
                onTabChanged(item.value);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.tabPillActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppTheme.primary : AppTheme.tabInactiveText,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (item.badgeCount != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

          return expanded ? Expanded(child: tabWidget) : tabWidget;
        }).toList(),
      ),
    );
  }
}
