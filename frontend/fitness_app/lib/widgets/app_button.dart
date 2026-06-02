import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final double? width;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.width,
    this.icon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: 54,
          child: widget.outlined
            ? _outlinedButton()
            : _filledButton(),
        ),
      ),
    );
  }

  Widget _filledButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.onPressed == null
          ? AppColors.textMuted
          : AppColors.accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: widget.onPressed != null ? [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ] : [],
      ),
      child: Center(child: _child(AppColors.background)),
    );
  }

  Widget _outlinedButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.onPressed == null
            ? AppColors.textMuted
            : AppColors.border,
          width: 1,
        ),
      ),
      child: Center(child: _child(
        widget.onPressed == null
          ? AppColors.textMuted
          : AppColors.textPrimary,
      )),
    );
  }

  Widget _child(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(widget.label, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: color, letterSpacing: 0.3)),
        ],
      );
    }
    return Text(widget.label, style: TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600,
      color: color, letterSpacing: 0.3));
  }
}