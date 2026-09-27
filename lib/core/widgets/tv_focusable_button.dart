import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/core/theme/app_theme.dart';

class TvFocusableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget label;
  final Widget? icon;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isFocused;
  final bool isJioLoggedIn;
  final Color? focusedBackgroundColor;
  final Color? unfocusedBackgroundColor;
  final Color? focusedTextColor;
  final Color? unfocusedTextColor;
  final Color? focusedBorderColor;
  final Color? unfocusedBorderColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const TvFocusableButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.isFocused = false,
    this.isJioLoggedIn = false,
    this.focusedBackgroundColor,
    this.unfocusedBackgroundColor,
    this.focusedTextColor,
    this.unfocusedTextColor,
    this.focusedBorderColor,
    this.unfocusedBorderColor,
    this.padding,
    this.borderRadius = 8.0,
  });

  @override
  State<TvFocusableButton> createState() => _TvFocusableButtonState();
}

class _TvFocusableButtonState extends State<TvFocusableButton> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _isFocused = widget.focusNode!.hasFocus;
      widget.focusNode!.addListener(_onFocusChange);
    }
  }

  @override
  void didUpdateWidget(covariant TvFocusableButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
      if (widget.focusNode != null) {
        _isFocused = widget.focusNode!.hasFocus;
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && widget.focusNode != null) {
      if (_isFocused != widget.focusNode!.hasFocus) {
        setState(() {
          _isFocused = widget.focusNode!.hasFocus;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _isFocused || widget.isFocused;

    final bg = hasFocus
        ? (widget.focusedBackgroundColor ?? AppColors.lightBronze)
        : (widget.unfocusedBackgroundColor ?? const Color(0xFF10121A));

    final fg = hasFocus
        ? (widget.focusedTextColor ?? AppColors.black)
        : (widget.unfocusedTextColor ?? AppColors.almondSilk);

    final border = hasFocus
        ? (widget.focusedBorderColor ?? AppColors.almondSilk)
        : (widget.unfocusedBorderColor ?? const Color(0xFF1E212D));

    return FocusableActionDetector(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
            const ActivateIntent(),
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
                  letterSpacing: 0.3,
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
