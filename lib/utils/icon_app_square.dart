import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IconAppSquare extends StatelessWidget {
  final double size;
  const IconAppSquare({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Recalculate size based on screen scale dynamically
    final double scaledSize = size.w; // responsive width-based scaling
    final double padding = scaledSize * 0.3;
    final double iconSize = scaledSize * 1.2;
    final double blur = scaledSize * 0.6;
    final double offsetY = scaledSize * 0.1;
    final double borderRadius = scaledSize * 0.3;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.25),
            blurRadius: blur,
            offset: Offset(0, offsetY),
          ),
        ],
      ),
      child: Icon(
        Icons.mosque_rounded,
        size: iconSize,
        color: cs.onPrimaryContainer,
      ),
    );
  }
}
