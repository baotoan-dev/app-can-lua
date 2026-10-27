import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? accentColor;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showText = false,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = primaryColor ?? const Color(0xFF1B5E20);
    final effectiveAccent = accentColor ?? const Color(0xFFFFB300);

    final logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectivePrimary,
            const Color(0xFF003300),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.6),
          width: size * 0.04,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _RiceScaleLogoPainter(accentColor: effectiveAccent),
        ),
      ),
    );

    if (!showText) return logoIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CÂN LÚA',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'NÔNG SẢN OFFLINE',
              style: TextStyle(
                color: effectiveAccent,
                fontSize: size * 0.24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RiceScaleLogoPainter extends CustomPainter {
  final Color accentColor;

  _RiceScaleLogoPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paint for scale platform and beam
    final scalePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final goldPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Base of scale
    canvas.drawLine(
      Offset(w * 0.2, h * 0.88),
      Offset(w * 0.8, h * 0.88),
      scalePaint,
    );

    // Center pillar
    canvas.drawLine(
      Offset(w * 0.5, h * 0.88),
      Offset(w * 0.5, h * 0.35),
      scalePaint,
    );

    // Horizontal balance beam
    canvas.drawLine(
      Offset(w * 0.12, h * 0.38),
      Offset(w * 0.88, h * 0.38),
      scalePaint,
    );

    // Left pan hanging strings and pan
    canvas.drawLine(
      Offset(w * 0.2, h * 0.38),
      Offset(w * 0.12, h * 0.60),
      scalePaint..strokeWidth = w * 0.05,
    );
    canvas.drawLine(
      Offset(w * 0.2, h * 0.38),
      Offset(w * 0.28, h * 0.60),
      scalePaint,
    );
    canvas.drawLine(
      Offset(w * 0.08, h * 0.60),
      Offset(w * 0.32, h * 0.60),
      scalePaint..strokeWidth = w * 0.07,
    );

    // Right pan hanging strings and pan
    canvas.drawLine(
      Offset(w * 0.8, h * 0.38),
      Offset(w * 0.72, h * 0.60),
      scalePaint..strokeWidth = w * 0.05,
    );
    canvas.drawLine(
      Offset(w * 0.8, h * 0.38),
      Offset(w * 0.88, h * 0.60),
      scalePaint,
    );
    canvas.drawLine(
      Offset(w * 0.68, h * 0.60),
      Offset(w * 0.92, h * 0.60),
      scalePaint..strokeWidth = w * 0.07,
    );

    // Golden Rice stalk grains in the center rising up
    final grains = [
      Offset(w * 0.5, h * 0.12),
      Offset(w * 0.42, h * 0.18),
      Offset(w * 0.58, h * 0.18),
      Offset(w * 0.40, h * 0.25),
      Offset(w * 0.60, h * 0.25),
    ];

    for (final grain in grains) {
      canvas.drawOval(
        Rect.fromCenter(
          center: grain,
          width: w * 0.14,
          height: h * 0.10,
        ),
        goldPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RiceScaleLogoPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
