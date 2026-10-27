import 'package:flutter/material.dart';

class AppResponsiveFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AppResponsiveFrame({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If on mobile or narrow screen, display standard full screen
        if (constraints.maxWidth <= maxWidth + 40) {
          return child;
        }

        final height = constraints.maxHeight - 40;
        final targetHeight = height > 0 ? height : constraints.maxHeight;

        // On desktop or wide tablet screens, display as an elegant, centered smartphone frame
        return Scaffold(
          backgroundColor: const Color(0xFF0F1713), // Deep obsidian forest background
          body: Center(
            child: Container(
              width: maxWidth,
              height: targetHeight,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(maxWidth, targetHeight),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

