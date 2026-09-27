import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/core/theme/app_theme.dart';

class CollapsibleSidebar extends StatefulWidget {
  final int selectedCategoryIndex;
  final int allCount;
  final int favoritesCount;
  final int jioCount;
  final int iptvCount;
  final bool isJioLoggedIn;
  final ValueChanged<bool>? onExpansionChanged;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<int> onExitRightFromCategory;
  final VoidCallback onExitRightFromAction;
  final VoidCallback onJioLoginPressed;
  final VoidCallback onSettingsPressed;

  const CollapsibleSidebar({
    super.key,
    required this.selectedCategoryIndex,
    required this.allCount,
    required this.favoritesCount,
    required this.jioCount,
    required this.iptvCount,
    required this.isJioLoggedIn,
    this.onExpansionChanged,
    required this.onCategorySelected,
    required this.onExitRightFromCategory,
    required this.onExitRightFromAction,
    required this.onJioLoginPressed,
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
  late final FocusNode jioLoginFocusNode;
  late final FocusNode settingsFocusNode;

  bool _isSidebarFocused = false;

  @override
  void initState() {
    super.initState();
    allCategoryFocusNode = FocusNode(debugLabel: 'Nav_All');
    favCategoryFocusNode = FocusNode(debugLabel: 'Nav_Fav');
    jioCategoryFocusNode = FocusNode(debugLabel: 'Nav_Jio');
    iptvCategoryFocusNode = FocusNode(debugLabel: 'Nav_IPTV');
    jioLoginFocusNode = FocusNode(debugLabel: 'Nav_JioLogin');
    settingsFocusNode = FocusNode(debugLabel: 'Nav_Settings');

    for (final node in [
      allCategoryFocusNode,
      favCategoryFocusNode,
      jioCategoryFocusNode,
      iptvCategoryFocusNode,
      jioLoginFocusNode,
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
    jioLoginFocusNode.removeListener(_checkFocusState);
    settingsFocusNode.removeListener(_checkFocusState);

    allCategoryFocusNode.dispose();
    favCategoryFocusNode.dispose();
    jioCategoryFocusNode.dispose();
    iptvCategoryFocusNode.dispose();
    jioLoginFocusNode.dispose();
    settingsFocusNode.dispose();
    super.dispose();
  }

  void _checkFocusState() {
    final hasFocus =
        allCategoryFocusNode.hasFocus ||
        favCategoryFocusNode.hasFocus ||
        jioCategoryFocusNode.hasFocus ||
        iptvCategoryFocusNode.hasFocus ||
        jioLoginFocusNode.hasFocus ||
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
        border: Border(
          right: BorderSide(color: Color(0xFF161822), width: 1.0),
        ),
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
                    border: Border.all(color: const Color(0xFF1E212D), width: 1.0),
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
            count: widget.allCount,
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
            count: widget.favoritesCount,
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
            count: widget.jioCount,
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
            count: widget.iptvCount,
            isSelected: widget.selectedCategoryIndex == 3,
            onSelect: () => widget.onCategorySelected(3),
            onExitRight: () => widget.onExitRightFromCategory(3),
            onMoveUp: () => jioCategoryFocusNode.requestFocus(),
            onMoveDown: () {
              if (!widget.isJioLoggedIn) {
                jioLoginFocusNode.requestFocus();
              } else {
                settingsFocusNode.requestFocus();
              }
            },
          ),

          const Spacer(),

          // Actions
          if (!widget.isJioLoggedIn) ...[
            _SidebarActionButton(
              focusNode: jioLoginFocusNode,
              icon: Icons.login_rounded,
              label: "JioTV Login",
              accentColor: AppColors.lightBronze,
              onPressed: widget.onJioLoginPressed,
              onExitRight: widget.onExitRightFromAction,
              onMoveUp: () => iptvCategoryFocusNode.requestFocus(),
              onMoveDown: () => settingsFocusNode.requestFocus(),
            ),
            const SizedBox(height: 6),
          ],

          _SidebarActionButton(
            focusNode: settingsFocusNode,
            icon: Icons.settings_rounded,
            label: "Settings",
            onPressed: widget.onSettingsPressed,
            onExitRight: widget.onExitRightFromAction,
            onMoveUp: () {
              if (!widget.isJioLoggedIn) {
                jioLoginFocusNode.requestFocus();
              } else {
                iptvCategoryFocusNode.requestFocus();
              }
            },
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
  final int count;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onExitRight;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _SidebarCategoryItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.count,
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
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
      if (widget.focusNode.hasFocus) {
        widget.onSelect();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color iconColor;
    Color countBg;
    Color countFg;
    Border? border;

    if (_isFocused) {
      bg = AppColors.lightBronze;
      fg = AppColors.black;
      iconColor = AppColors.black;
      countBg = AppColors.black.withValues(alpha: 0.18);
      countFg = AppColors.black;
      border = Border.all(color: AppColors.almondSilk, width: 1.5);
    } else if (widget.isSelected) {
      bg = const Color(0xFF12141D);
      fg = AppColors.almondSilk;
      iconColor = AppColors.lightBronze;
      countBg = const Color(0xFF1B1E2B);
      countFg = AppColors.lightBronze;
      border = Border.all(
        color: AppColors.lightBronze.withValues(alpha: 0.35),
        width: 1.0,
      );
    } else {
      bg = Colors.transparent;
      fg = AppColors.almondSilk.withValues(alpha: 0.65);
      iconColor = AppColors.lightBronze.withValues(alpha: 0.45);
      countBg = const Color(0xFF10121A);
      countFg = AppColors.almondSilk.withValues(alpha: 0.45);
      border = null;
    }

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onExitRight();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onMoveUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onMoveDown();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: border,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: countBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${widget.count}",
                  style: TextStyle(
                    color: countFg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
  final Color? accentColor;
  final VoidCallback onPressed;
  final VoidCallback onExitRight;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _SidebarActionButton({
    required this.focusNode,
    required this.icon,
    required this.label,
    this.accentColor,
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
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _isFocused
        ? AppColors.black
        : (widget.accentColor ?? AppColors.almondSilk.withValues(alpha: 0.75));

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onExitRight();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onMoveUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onMoveDown();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isFocused ? AppColors.lightBronze : const Color(0xFF10121A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? AppColors.almondSilk
                  : const Color(0xFF1C1E2A),
              width: _isFocused ? 1.5 : 1.0,
            ),
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
                    fontWeight: FontWeight.bold,
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
