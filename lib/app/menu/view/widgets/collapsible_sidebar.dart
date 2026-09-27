import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/core/theme/app_theme.dart';

class CollapsibleSidebar extends StatefulWidget {
  final int selectedCategoryIndex;
  final ValueChanged<bool>? onExpansionChanged;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<int> onExitRightFromCategory;
  final VoidCallback onExitRightFromAction;
  final VoidCallback onSettingsPressed;

  const CollapsibleSidebar({
    super.key,
    required this.selectedCategoryIndex,
    this.onExpansionChanged,
    required this.onCategorySelected,
    required this.onExitRightFromCategory,
    required this.onExitRightFromAction,
    required this.onSettingsPressed,
  });

  @override
  State<CollapsibleSidebar> createState() => CollapsibleSidebarState();
}

class CollapsibleSidebarState extends State<CollapsibleSidebar> {
  late final FocusNode allCategoryFocusNode;
  late final FocusNode favCategoryFocusNode;
  late final FocusNode jioCategoryFocusNode;
  late final FocusNode iptvCategoryFocusNode;
  late final FocusNode settingsFocusNode;

  bool _isSidebarFocused = false;

  @override
  void initState() {
    super.initState();
    allCategoryFocusNode = FocusNode(debugLabel: 'Nav_All');
    favCategoryFocusNode = FocusNode(debugLabel: 'Nav_Fav');
    jioCategoryFocusNode = FocusNode(debugLabel: 'Nav_Jio');
    iptvCategoryFocusNode = FocusNode(debugLabel: 'Nav_IPTV');
    settingsFocusNode = FocusNode(debugLabel: 'Nav_Settings');

    for (final node in [
      allCategoryFocusNode,
      favCategoryFocusNode,
      jioCategoryFocusNode,
      iptvCategoryFocusNode,
      settingsFocusNode,
    ]) {
      node.addListener(_checkFocusState);
    }
  }

  @override
  void dispose() {
    allCategoryFocusNode.removeListener(_checkFocusState);
    favCategoryFocusNode.removeListener(_checkFocusState);
    jioCategoryFocusNode.removeListener(_checkFocusState);
    iptvCategoryFocusNode.removeListener(_checkFocusState);
    settingsFocusNode.removeListener(_checkFocusState);

    allCategoryFocusNode.dispose();
    favCategoryFocusNode.dispose();
    jioCategoryFocusNode.dispose();
    iptvCategoryFocusNode.dispose();
    settingsFocusNode.dispose();
    super.dispose();
  }

  void _checkFocusState() {
    final hasFocus =
        allCategoryFocusNode.hasFocus ||
        favCategoryFocusNode.hasFocus ||
        jioCategoryFocusNode.hasFocus ||
        iptvCategoryFocusNode.hasFocus ||
        settingsFocusNode.hasFocus;

    if (_isSidebarFocused != hasFocus) {
      setState(() => _isSidebarFocused = hasFocus);
      widget.onExpansionChanged?.call(hasFocus);
    }
  }

  void focusActiveCategory() {
    switch (widget.selectedCategoryIndex) {
      case 1:
        favCategoryFocusNode.requestFocus();
        break;
      case 2:
        jioCategoryFocusNode.requestFocus();
        break;
      case 3:
        iptvCategoryFocusNode.requestFocus();
        break;
      case 0:
      default:
        allCategoryFocusNode.requestFocus();
        break;
    }
  }

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
            focusNode: allCategoryFocusNode,
            icon: Icons.tv_rounded,
            label: "All Channels",
            isSelected: widget.selectedCategoryIndex == 0,
            onSelect: () => widget.onCategorySelected(0),
            onExitRight: () => widget.onExitRightFromCategory(0),
            onMoveUp: () => settingsFocusNode.requestFocus(),
            onMoveDown: () => favCategoryFocusNode.requestFocus(),
          ),
          const SizedBox(height: 6),
          _SidebarCategoryItem(
            focusNode: favCategoryFocusNode,
            icon: Icons.star_rounded,
            label: "Favorites",
            isSelected: widget.selectedCategoryIndex == 1,
            onSelect: () => widget.onCategorySelected(1),
            onExitRight: () => widget.onExitRightFromCategory(1),
            onMoveUp: () => allCategoryFocusNode.requestFocus(),
            onMoveDown: () => jioCategoryFocusNode.requestFocus(),
          ),
          const SizedBox(height: 6),
          _SidebarCategoryItem(
            focusNode: jioCategoryFocusNode,
            icon: Icons.cell_tower_rounded,
            label: "JioTV",
            isSelected: widget.selectedCategoryIndex == 2,
            onSelect: () => widget.onCategorySelected(2),
            onExitRight: () => widget.onExitRightFromCategory(2),
            onMoveUp: () => favCategoryFocusNode.requestFocus(),
            onMoveDown: () => iptvCategoryFocusNode.requestFocus(),
          ),
          const SizedBox(height: 6),
          _SidebarCategoryItem(
            focusNode: iptvCategoryFocusNode,
            icon: Icons.public_rounded,
            label: "IPTV",
            isSelected: widget.selectedCategoryIndex == 3,
            onSelect: () => widget.onCategorySelected(3),
            onExitRight: () => widget.onExitRightFromCategory(3),
            onMoveUp: () => jioCategoryFocusNode.requestFocus(),
            onMoveDown: () => settingsFocusNode.requestFocus(),
          ),

          const Spacer(),

          // Actions
          _SidebarActionButton(
            focusNode: settingsFocusNode,
            icon: Icons.settings_rounded,
            label: "Settings",
            onPressed: widget.onSettingsPressed,
            onExitRight: widget.onExitRightFromAction,
            onMoveUp: () => iptvCategoryFocusNode.requestFocus(),
            onMoveDown: () => allCategoryFocusNode.requestFocus(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarCategoryItem extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onExitRight;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _SidebarCategoryItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onSelect,
    required this.onExitRight,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<_SidebarCategoryItem> createState() => _SidebarCategoryItemState();
}

class _SidebarCategoryItemState extends State<_SidebarCategoryItem> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant _SidebarCategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocus);
      widget.focusNode.addListener(_handleFocus);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
      // NOTE: Do not call widget.onSelect() here!
      // Merely highlighting a category in the sidebar must NOT prematurely
      // wipe or switch the channel grid. Selection is committed when the user
      // explicitly presses Select/Enter or navigates right into the grid.
    }
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }

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

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        if (mounted && _isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onExitRight();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onMoveUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onMoveDown();
            return KeyEventResult.handled;
          } else if (_isSelectKey(event.logicalKey)) {
            widget.onSelect();
            widget.onExitRight();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          widget.focusNode.requestFocus();
          widget.onSelect();
          widget.onExitRight();
        },
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
      ),
    );
  }
}

class _SidebarActionButton extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback onExitRight;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _SidebarActionButton({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.onExitRight,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant _SidebarActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocus);
      widget.focusNode.addListener(_handleFocus);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

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
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        if (mounted && _isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onExitRight();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onMoveUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onMoveDown();
            return KeyEventResult.handled;
          } else if (_isSelectKey(event.logicalKey)) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          widget.focusNode.requestFocus();
          widget.onPressed();
        },
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
