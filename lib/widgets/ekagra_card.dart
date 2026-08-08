import 'package:flutter/material.dart';

import '../config/theme.dart';

class EkagraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;
  final double? radius;

  const EkagraCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(EkagraSpacing.lg),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? EkagraColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius ?? EkagraRadius.lg),
        border: border ??
            Border.all(
              color: EkagraColors.primaryLight.withValues(alpha: 0.25),
            ),
        boxShadow: [
          BoxShadow(
            color: EkagraColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? EkagraRadius.lg),
        child: content,
      ),
    );
  }
}
