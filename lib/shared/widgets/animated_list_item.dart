import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int baseDelayMs;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelayMs = 60,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * baseDelayMs + 50),
          duration: 350.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: index * baseDelayMs + 50),
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
