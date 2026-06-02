import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}

// ── Glass Card ────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double blur;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.blur = 10,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tint ?? AppColors.cardGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cardGlassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          )),
      ],
    );
  }
}