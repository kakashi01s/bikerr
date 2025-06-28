import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme.dart';

class AnimatedRotatingMarker extends StatefulWidget {
  final LatLng targetPosition;
  final double heading;
  final Color color;
  const AnimatedRotatingMarker({
    super.key,
    required this.targetPosition,
    required this.heading, required this.color,
  });

  @override
  State<AnimatedRotatingMarker> createState() => _AnimatedRotatingMarkerState();
}

class _AnimatedRotatingMarkerState extends State<AnimatedRotatingMarker>
    with SingleTickerProviderStateMixin {
  LatLng? _oldPosition;

  @override
  void didUpdateWidget(covariant AnimatedRotatingMarker oldWidget) {
    if (widget.targetPosition != oldWidget.targetPosition) {
      _oldPosition = oldWidget.targetPosition;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final start = _oldPosition ?? widget.targetPosition;
    final end = widget.targetPosition;

    return TweenAnimationBuilder<LatLng>(
      tween: Tween<LatLng>(begin: start, end: end),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: widget.heading * (3.1415926535 / 180), // Convert degrees to radians
          child: const Icon(
            Icons.navigation,

            size: 30,
          ),
        );
      },
    );
  }
}
