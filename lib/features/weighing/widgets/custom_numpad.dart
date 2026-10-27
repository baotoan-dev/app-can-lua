import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CustomNumpad extends StatelessWidget {
  final String currentInput;
  final int nextBagIndex;
  final Function(String digit) onDigitPress;
  final VoidCallback onDeletePress;
  final VoidCallback onClearPress;
  final Function(double delta) onQuickAdd;
  final VoidCallback onSubmit;

  const CustomNumpad({
    super.key,
    required this.currentInput,
    required this.nextBagIndex,
    required this.onDigitPress,
    required this.onDeletePress,
    required this.onClearPress,
    required this.onQuickAdd,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        border: const Border(
          top: BorderSide(color: Color(0xFFD6DDD6), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // High-Contrast Modern LCD Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0C240E),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E4D22), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Next Bag Index Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF388E3C), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF81C784),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BAO #$nextBagIndex',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Digital Weight Readout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentInput.isEmpty ? '0.0' : currentInput,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: currentInput.isEmpty
                              ? const Color(0xFF3A5C3C)
                              : const Color(0xFFFFD54F),
                          fontFamily: 'monospace',
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA5D6A7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tactile 3D Keypad Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  _buildRow(['7', '8', '9', 'DEL']),
                  const SizedBox(height: 7),
                  _buildRow(['4', '5', '6', 'C']),
                  const SizedBox(height: 7),
                  _buildRow(['1', '2', '3', '+0.5']),
                  const SizedBox(height: 7),
                  _buildRow(['0', '.', '+0.2', 'NHẬP']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.5),
            child: _buildKeyButton(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton(String key) {
    final bool isSubmit = (key == 'NHẬP');
    final bool isAction = (key == 'DEL' || key == 'C');
    final bool isQuickAdd = (key.startsWith('+'));

    final Color bgColor;
    final Color textColor;
    final Border? border;
    final List<BoxShadow> shadows;

    if (isSubmit) {
      bgColor = AppTheme.accent;
      textColor = Colors.white;
      border = Border.all(color: const Color(0xFFFF8F00), width: 1.2);
      shadows = [
        BoxShadow(
          color: const Color(0xFFE65100).withValues(alpha: 0.35),
          offset: const Offset(0, 3),
          blurRadius: 6,
        ),
      ];
    } else if (isAction) {
      bgColor = const Color(0xFFFDE8E8);
      textColor = const Color(0xFFC62828);
      border = Border.all(color: const Color(0xFFFFCDD2), width: 1.2);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 2),
          blurRadius: 2,
        ),
      ];
    } else if (isQuickAdd) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFB45309);
      border = Border.all(color: const Color(0xFFFFE082), width: 1.3);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 2),
          blurRadius: 2,
        ),
      ];
    } else {
      bgColor = Colors.white;
      textColor = AppTheme.textPrimary;
      border = Border.all(color: const Color(0xFFD6DDD6), width: 1.2);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 2),
          blurRadius: 3,
        ),
      ];
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: shadows,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          splashColor: isSubmit
              ? Colors.white.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.15),
          highlightColor: isSubmit
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          onTap: () {
            if (isSubmit) {
              onSubmit();
            } else if (key == 'DEL') {
              onDeletePress();
            } else if (key == 'C') {
              onClearPress();
            } else if (isQuickAdd) {
              final delta = double.tryParse(key.replaceAll('+', '')) ?? 0.0;
              onQuickAdd(delta);
            } else {
              onDigitPress(key);
            }
          },
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: border,
              gradient: isSubmit
                  ? const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFFF6D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: isAction && key == 'DEL'
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: Color(0xFFC62828),
                  )
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: isSubmit ? 16 : (isQuickAdd ? 15 : 22),
                      fontWeight: FontWeight.w900,
                      color: isSubmit
                          ? Colors.white
                          : (isAction ? const Color(0xFFC62828) : textColor),
                      letterSpacing: isSubmit ? 0.8 : 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
