import 'dart:math';
import 'package:flutter/material.dart';
import 'animated_heart.dart';

class LikeAnimationOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final bool enabled;

  const LikeAnimationOverlay({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.enabled = true,
  });

  @override
  State<LikeAnimationOverlay> createState() => LikeAnimationOverlayState();
}

class LikeAnimationOverlayState extends State<LikeAnimationOverlay> {
  final List<_HeartData> _hearts = [];
  int _heartIdCounter = 0;

  // Vibrant color palette for hearts
  final List<Color> _heartColors = [
    const Color(0xFFFF6B9D), // Pink
    const Color(0xFFFF5757), // Red
    const Color(0xFFFFA07A), // Light Salmon
    const Color(0xFFFF69B4), // Hot Pink
    const Color(0xFFFF1493), // Deep Pink
    const Color(0xFFFF4500), // Orange Red
    const Color(0xFFFF6347), // Tomato
    const Color(0xFFFF00FF), // Magenta
    const Color(0xFFDA70D6), // Orchid
    const Color(0xFFBA55D3), // Medium Orchid
  ];

  Color _getRandomColor() {
    return _heartColors[Random().nextInt(_heartColors.length)];
  }

  void handleDoubleTap(TapDownDetails details) {
    if (!widget.enabled) return;

    final heartId = _heartIdCounter++;
    
    setState(() {
      _hearts.add(_HeartData(
        id: heartId,
        position: details.localPosition,
        color: _getRandomColor(),
      ));
    });

    // Trigger callback
    widget.onDoubleTap?.call();

    // Remove heart after animation completes
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _hearts.removeWhere((h) => h.id == heartId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Render all active hearts
        ..._hearts.map((heart) => AnimatedHeart(
              key: ValueKey(heart.id),
              position: heart.position,
              color: heart.color,
            )),
      ],
    );
  }
}

class _HeartData {
  final int id;
  final Offset position;
  final Color color;

  _HeartData({
    required this.id,
    required this.position,
    required this.color,
  });
}
