import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Three dots that light up white one by one in a loop,
/// creating a sequential loading indicator.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const int _dotCount = 3;
  static const double _dotSize = 8.0;
  static const double _dotSpacing = 10.0;

  @override
  void initState() {
    super.initState();
    // Each full cycle = 3 steps (one per dot), 400 ms per step
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Which dot (0-2) is currently "lit"
        final int activeDot = (_controller.value * _dotCount).floor() % _dotCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_dotCount, (index) {
            final bool isActive = index == activeDot;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: _dotSpacing / 2),
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.white : AppColors.dotInactive,
              ),
            );
          }),
        );
      },
    );
  }
}
