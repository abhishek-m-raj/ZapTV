import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget? icon;
  final Widget label;
  final bool isJioLoggedIn;
  final bool isFocused;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? unfocusedBackgroundColor;
  final Color? focusedBackgroundColor;
  final Color? unfocusedTextColor;
  final Color? focusedTextColor;
  final Color? unfocusedBorderColor;
  final Color? focusedBorderColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const TvFocusableButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.isJioLoggedIn = false,
    this.isFocused = false,
    this.autofocus = false,
    this.focusNode,
    this.unfocusedBackgroundColor,
    this.focusedBackgroundColor,
    this.unfocusedTextColor,
    this.focusedTextColor,
    this.unfocusedBorderColor,
    this.focusedBorderColor,
    this.padding,
    this.borderRadius = 10,
  });

  @override
  State<TvFocusableButton> createState() => _TvFocusableButtonState();
}

class _TvFocusableButtonState extends State<TvFocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final hasFocus = _isFocused || widget.isFocused;

    Color bg;
    Color border;
    Color fg;

    if (widget.isJioLoggedIn) {
      if (hasFocus) {
        bg = widget.focusedBackgroundColor ?? Colors.green.shade600;
        border = widget.focusedBorderColor ?? Colors.white;
        fg = widget.focusedTextColor ?? Colors.white;
      } else {
        bg =
            widget.unfocusedBackgroundColor ??
            Colors.green.shade900.withValues(alpha: 0.5);
        border =
            widget.unfocusedBorderColor ??
            Colors.green.shade400.withValues(alpha: 0.4);
        fg = widget.unfocusedTextColor ?? Colors.green.shade200;
      }
    } else {
      if (hasFocus) {
        bg = widget.focusedBackgroundColor ?? Colors.white;
        border = widget.focusedBorderColor ?? Colors.white;
        fg = widget.focusedTextColor ?? const Color(0xFF101114);
      } else {
        bg = widget.unfocusedBackgroundColor ?? const Color(0xFF20232E);
        border =
            widget.unfocusedBorderColor ?? Colors.white.withValues(alpha: 0.12);
        fg = widget.unfocusedTextColor ?? Colors.white;
      }
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
            const ActivateIntent(),
        const SingleActivator(
          LogicalKeyboardKey.numpadEnter,
          includeRepeats: false,
        ): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.select, includeRepeats: false):
            const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
            const ActivateIntent(),
        const SingleActivator(
          LogicalKeyboardKey.gameButtonA,
          includeRepeats: false,
        ): const ActivateIntent(),
      },
      child: InkWell(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onTap: widget.onPressed,
        onFocusChange: (focusValue) {
          setState(() {
            _isFocused = focusValue;
          });
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            hasFocus ? 1.02 : 1.0,
            hasFocus ? 1.02 : 1.0,
            1.0,
          ),
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: border, width: hasFocus ? 2.0 : 1.0),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: widget.isJioLoggedIn
                          ? Colors.green.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 20),
                  child: widget.icon!,
                ),
                const SizedBox(width: 10),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
                child: widget.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
