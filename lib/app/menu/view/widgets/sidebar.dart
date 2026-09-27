import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/core/theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedCategoryIndex;
  final ValueChanged<int> onCategorySelected;
  final VoidCallback onSettingsPressed;

  const Sidebar({
    super.key,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240.0,
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(right: BorderSide(color: Color(0xFF161822), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // App Logo / Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10121A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1E212D),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.live_tv_rounded,
                    color: AppColors.lightBronze,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  "ZapTV",
                  style: TextStyle(
                    color: AppColors.almondSilk,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Categories
          _SidebarCategoryItem(
            icon: Icons.tv_rounded,
            label: "All Channels",
            isSelected: selectedCategoryIndex == 0,
            onFocus: () => onCategorySelected(0),
          ),
          const SizedBox(height: 6),
          _SidebarCategoryItem(
            icon: Icons.star_rounded,
            label: "Favorites",
            isSelected: selectedCategoryIndex == 1,
            onFocus: () => onCategorySelected(1),
          ),
          const SizedBox(height: 6),
          _SidebarCategoryItem(
            icon: Icons.cell_tower_rounded,
            label: "JioTV",
            isSelected: selectedCategoryIndex == 2,
            onFocus: () => onCategorySelected(2),
          ),
          const SizedBox(height: 6),
          _SidebarCategoryItem(
            icon: Icons.public_rounded,
            label: "IPTV",
            isSelected: selectedCategoryIndex == 3,
            onFocus: () => onCategorySelected(3),
          ),

          const Spacer(),

          // Settings
          _SidebarActionButton(
            icon: Icons.settings_rounded,
            label: "Settings",
            onPressed: onSettingsPressed,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarCategoryItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onFocus;

  const _SidebarCategoryItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onFocus,
  });

  @override
  State<_SidebarCategoryItem> createState() => _SidebarCategoryItemState();
}

class _SidebarCategoryItemState extends State<_SidebarCategoryItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color iconColor;
    Border? border;
    List<BoxShadow>? shadows;

    if (_isFocused) {
      bg = AppColors.lightBronze;
      fg = AppColors.black;
      iconColor = AppColors.black;
      border = Border.all(color: AppColors.almondSilk, width: 2.0);
      shadows = [
        BoxShadow(
          color: AppColors.lightBronze.withValues(alpha: 0.4),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
    } else if (widget.isSelected) {
      bg = const Color(0xFF141622);
      fg = AppColors.almondSilk;
      iconColor = AppColors.lightBronze;
      border = Border.all(
        color: AppColors.lightBronze.withValues(alpha: 0.35),
        width: 1.0,
      );
      shadows = null;
    } else {
      bg = Colors.transparent;
      fg = AppColors.almondSilk.withValues(alpha: 0.65);
      iconColor = AppColors.lightBronze.withValues(alpha: 0.45);
      border = null;
      shadows = null;
    }

    return InkWell(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused) widget.onFocus();
      },
      onTap: widget.onFocus,
      // Remove the default InkWell splash/highlight to keep our custom styling
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        transform: Matrix4.diagonal3Values(
          _isFocused ? 1.03 : 1.0,
          _isFocused ? 1.03 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
          boxShadow: shadows,
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: _isFocused || widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _isFocused = false;

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  @override
  Widget build(BuildContext context) {
    final fg = _isFocused
        ? AppColors.black
        : AppColors.almondSilk.withValues(alpha: 0.8);

    return Focus(
      onFocusChange: (focused) {
        if (mounted && _isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (_isSelectKey(event.logicalKey)) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          transform: Matrix4.diagonal3Values(
            _isFocused ? 1.04 : 1.0,
            _isFocused ? 1.04 : 1.0,
            1.0,
          ),
          decoration: BoxDecoration(
            color: _isFocused ? AppColors.lightBronze : const Color(0xFF10121A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? AppColors.almondSilk
                  : const Color(0xFF1E212D),
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.lightBronze.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: fg, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
              if (_isFocused) ...[
                Icon(Icons.arrow_forward_ios_rounded, color: fg, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
