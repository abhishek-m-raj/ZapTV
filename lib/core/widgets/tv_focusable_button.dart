import 'package:flutter/material.dart';

class TvFocusableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget? icon;
  final Widget label;
  final bool isJioLoggedIn;
  final bool isFocused;
  final bool autofocus;
  final FocusNode? focusNode;

  const TvFocusableButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.isJioLoggedIn = false,
    this.isFocused = false,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<TvFocusableButton> createState() => _TvFocusableButtonState();
}

class _TvFocusableButtonState extends State<TvFocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFocus = _isFocused || widget.isFocused;

    return InkWell(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onTap: widget.onPressed,
      onFocusChange: (focusValue) {
        setState(() {
          _isFocused = focusValue;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: hasFocus
              ? theme.colorScheme.primary
              : (widget.isJioLoggedIn
                    ? Colors.green.shade800
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.15,
                      )),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFocus ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: hasFocus
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  color: hasFocus
                      ? Colors.white
                      : (widget.isJioLoggedIn
                            ? Colors.white
                            : theme.colorScheme.onSurface),
                ),
                child: widget.icon!,
              ),
              const SizedBox(width: 8),
            ],
            DefaultTextStyle(
              style: TextStyle(
                color: hasFocus
                    ? Colors.white
                    : (widget.isJioLoggedIn
                          ? Colors.white
                          : theme.colorScheme.onSurface),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              child: widget.label,
            ),
          ],
        ),
      ),
    );
  }
}
