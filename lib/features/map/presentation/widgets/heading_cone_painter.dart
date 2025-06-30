import 'dart:math' as math;

import 'package:bikerr/core/theme.dart';
import 'package:flutter/cupertino.dart';

class HeadingConePainter extends CustomPainter {
  final Color? color;
  final double heading;
  final double coneAngle;
  final double radius;

  HeadingConePainter({
    required this.color,
    required this.heading,
    this.coneAngle = math.pi / 3,
    this.radius = 180,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final path = Path()..moveTo(center.dx, center.dy);

    final correctedHeading = heading - math.pi / 2;

    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      correctedHeading - coneAngle / 2,
      coneAngle,
      false,
    );
    path.close();

    final gradient = RadialGradient(
      colors: [
        color?.withOpacity(0.4) ?? CupertinoColors.activeBlue.withOpacity(0.4),
        CupertinoColors.transparent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeadingConePainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.coneAngle != coneAngle ||
        oldDelegate.radius != radius;
  }
}


class MapHeadingMarker extends StatelessWidget {
  final double heading;
  final bool isThisDevice;
  final Color? color;

  const MapHeadingMarker({
    super.key,
    required this.heading,
    required this.isThisDevice,
required this.color
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter:  HeadingConePainter(
              color: AppColors.markerBg1,
              heading: heading,
              radius: isThisDevice? 100 : 0,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isThisDevice ? CupertinoColors.destructiveRed : CupertinoColors.activeBlue,
              shape: BoxShape.circle,
              border: Border.all(color: CupertinoColors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 1),
                  blurRadius: 10,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
