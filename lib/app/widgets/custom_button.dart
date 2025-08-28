import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFullWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isOutlined;
  final Color? borderColor;
  final double? elevation;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = true,
    this.borderRadius = 8.0,
    this.padding,
    this.isOutlined = false,
    this.borderColor,
    this.elevation,
  });

  const CustomButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.textColor,
    this.isFullWidth = true,
    this.borderRadius = 8.0,
    this.padding,
    this.elevation,
  })  : isOutlined = true,
        backgroundColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: isOutlined
          ? Colors.transparent
          : backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: textColor ??
          (isOutlined
              ? (borderColor ?? theme.colorScheme.primary)
              : Colors.white),
      elevation: elevation,
      padding: padding ??
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: isOutlined
            ? BorderSide(
                color: borderColor ?? theme.colorScheme.primary,
                width: 1.0,
              )
            : BorderSide.none,
      ),
    );

    final button = ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: child,
    );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}
