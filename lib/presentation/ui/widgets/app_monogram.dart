import 'package:flutter/material.dart';

/// Gün 18: uygulama monogramı (kulaklık + ses dalgası) artık paylaşımlı.
/// Daha önce yalnızca izin sayfasının özel `_MonogramPainter`'ı olarak
/// yaşıyordu; onboarding karşılama sayfası da aynı imzayı kullanır.
///
/// [size] boyunca kare bir alan çizer; vuruş kalınlığı ve oranlar
/// 32x32 sanal tuvale göre ölçeklenir.
class AppMonogram extends StatelessWidget {
  const AppMonogram({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MonogramPainter(color: effectiveColor),
      ),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  _MonogramPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * s;

    // Headphone arch (cubic bezier)
    final arch = Path()
      ..moveTo(5 * s, 16 * s)
      ..cubicTo(5 * s, 9.925 * s, 9.925 * s, 5 * s, 16 * s, 5 * s)
      ..cubicTo(22.075 * s, 5 * s, 27 * s, 9.925 * s, 27 * s, 16 * s);
    canvas.drawPath(arch, strokePaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Sol kulaklık
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * s, 16 * s, 3.5 * s, 7.5 * s),
        Radius.circular(1.75 * s),
      ),
      fillPaint,
    );
    // Sağ kulaklık
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24.5 * s, 16 * s, 3.5 * s, 7.5 * s),
        Radius.circular(1.75 * s),
      ),
      fillPaint,
    );

    // Ses dalgaları
    final barPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2 * s;

    final barPaintThick = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * s;

    canvas.drawLine(
        Offset(11 * s, 18.5 * s), Offset(11 * s, 13.5 * s), barPaint);
    canvas.drawLine(
        Offset(14.5 * s, 21 * s), Offset(14.5 * s, 11 * s), barPaint);
    canvas.drawLine(
        Offset(18 * s, 23 * s), Offset(18 * s, 9 * s), barPaintThick);
    canvas.drawLine(
        Offset(21.5 * s, 19.5 * s), Offset(21.5 * s, 12.5 * s), barPaint);
  }

  @override
  bool shouldRepaint(covariant _MonogramPainter oldDelegate) =>
      oldDelegate.color != color;
}
