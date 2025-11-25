import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'military_decorations.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final double? height;
  final double? width;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.height,
    this.width,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: CornerBrackets(
        color: widget.onPressed == null
            ? AppColors.slate
            : (widget.isOutlined ? AppColors.white : AppColors.primary),
        length: 8,
        thickness: 1.5,
        offset: -4, // Brackets slightly outside
        child: SizedBox(
          height: widget.height ?? 56,
          width: widget.width,
          child: widget.isOutlined
              ? OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isHovered
                        ? (widget.foregroundColor ?? AppColors.white)
                        : Colors.transparent,
                    foregroundColor: _isHovered
                        ? (widget.backgroundColor ?? AppColors.primary)
                        : (widget.foregroundColor ?? AppColors.white),
                    side: BorderSide(
                      color: widget.borderColor ?? AppColors.white,
                      width: 1,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding:
                        widget.padding ??
                        const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: _buildContent(),
                )
              : ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isHovered
                        ? AppColors.tertiary
                        : (widget.backgroundColor ?? AppColors.white),
                    foregroundColor: _isHovered
                        ? AppColors.white
                        : (widget.foregroundColor ?? AppColors.primary),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding:
                        widget.padding ??
                        const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: _buildContent(),
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isOutlined
                ? (_isHovered ? AppColors.primary : AppColors.white)
                : (_isHovered ? AppColors.white : AppColors.primary),
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (widget.text.isNotEmpty)
            Text(
              widget.text.toUpperCase(),
              style: AppTextStyles.labelLarge.copyWith(
                color: widget.isOutlined
                    ? (_isHovered
                          ? (widget.backgroundColor ?? AppColors.primary)
                          : (widget.foregroundColor ?? AppColors.white))
                    : (_isHovered
                          ? AppColors.white
                          : (widget.foregroundColor ?? AppColors.primary)),
                letterSpacing: 1.5,
              ),
            ),

          Icon(widget.icon, size: 18),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text.toUpperCase(),
          style: AppTextStyles.labelLarge.copyWith(
            color: widget.isOutlined
                ? (_isHovered
                      ? (widget.backgroundColor ?? AppColors.primary)
                      : (widget.foregroundColor ?? AppColors.white))
                : (_isHovered
                      ? AppColors.white
                      : (widget.foregroundColor ?? AppColors.primary)),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
