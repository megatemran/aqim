import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IconAppCircle extends StatelessWidget {
  final double size;

  const IconAppCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    // Everything will scale relative to "size"
    final double padding = size * 0.4; // circle thickness
    final double iconSize = size * 1.5; // inner icon size
    final double blur = size * 0.8; // shadow softness
    final double offsetY = size * 0.3; // shadow offset
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(padding.w),
      decoration: BoxDecoration(
        color: cs.onPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5F4F).withValues(alpha: 0.3),
            blurRadius: blur,
            offset: Offset(0, offsetY),
          ),
        ],
      ),
      child: Icon(Icons.mosque_rounded, size: iconSize.sp, color: Colors.white),
    );
  }
}
