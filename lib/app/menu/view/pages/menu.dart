import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/menu/view/widgets/channel_options_dialog.dart';
import 'package:zaptv/app/menu/view/widgets/collapsible_sidebar.dart';
import 'package:zaptv/app/settings/view/pages/settings_page.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/hive_db.dart';
import 'package:zaptv/core/theme/app_theme.dart';

class MenuPage extends StatefulWidget {
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels;
  final int initialCategoryIndex;
  final Function(
    ChannelEntity channel,
    List<ChannelEntity> playlist,
    int categoryIndex,
  )
  onChannelSelected;
  final VoidCallback onPop;
  final VoidCallback? onJioLoginSuccess;

  const MenuPage({
    super.key,
    required this.currentChannel,
    required this.channels,
    this.initialCategoryIndex = 0,
    required this.onChannelSelected,
    required this.onPop,
    this.onJioLoginSuccess,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final GlobalKey<CollapsibleSidebarState> _sidebarKey =
      GlobalKey<CollapsibleSidebarState>();

  late ChannelEntity currentChannel;
  late int _selectedCategoryIndex; // 0: All, 1: Favorites, 2: JioTV, 3: IPTV
  final HiveDb _hiveDb = loc<HiveDb>();

  // Channel Lists
  late final List<ChannelEntity> _allChannels;
  late final List<ChannelEntity> _jioChannels;
  late final List<ChannelEntity> _iptvChannels;
  List<ChannelEntity> _displayedChannels = const [];

  late final ValueNotifier<ChannelEntity?> _focusedChannelNotifier;

  // Managed FocusNodes for Grid channel tiles to guarantee focus restoration
  final Map<String, FocusNode> _tileFocusNodes = {};
  late final FocusNode _emptyStateFocusNode;

  bool _isSidebarOpen = false;
  bool _hasInitiallyAutofocused = false;

  @override
  void initState() {
    super.initState();
    currentChannel = widget.currentChannel;
    _selectedCategoryIndex = widget.initialCategoryIndex;

    _allChannels = widget.channels;
    _jioChannels = widget.channels
        .where((c) => c.id.endsWith('-jiotv'))
        .toList();
    _iptvChannels = widget.channels
        .where((c) => !c.id.endsWith('-jiotv'))
        .toList();
    _updateDisplayedChannels();

    final hasCurrent = _displayedChannels.any((c) => c.id == currentChannel.id);
    _focusedChannelNotifier = ValueNotifier<ChannelEntity?>(
      hasCurrent
          ? currentChannel
          : (_displayedChannels.isNotEmpty
                ? _displayedChannels.first
                : currentChannel),
    );

    _emptyStateFocusNode = FocusNode(debugLabel: 'GridEmptyState');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasInitiallyAutofocused = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusedChannelNotifier.dispose();
    _emptyStateFocusNode.dispose();
    for (final node in _tileFocusNodes.values) {
      node.dispose();
    }
    _tileFocusNodes.clear();
    super.dispose();
  }

  FocusNode _getTileFocusNode(String channelId) {
    return _tileFocusNodes.putIfAbsent(
      channelId,
      () => FocusNode(debugLabel: 'ChannelTile_$channelId'),
    );
  }

  void _updateDisplayedChannels() {
    if (_selectedCategoryIndex == 1) {
      _displayedChannels = widget.channels
          .where((c) => _isFavorite(c))
          .toList();
    } else if (_selectedCategoryIndex == 2) {
      _displayedChannels = _jioChannels;
    } else if (_selectedCategoryIndex == 3) {
      _displayedChannels = _iptvChannels;
    } else {
      _displayedChannels = _allChannels;
    }
  }

  bool _isFavorite(ChannelEntity channel) {
    return _hiveDb.getData(channel.id, 'fav') == true;
  }

  void _toggleFavorite(ChannelEntity channel) {
    final isFav = _isFavorite(channel);
    if (isFav) {
      _hiveDb.deleteItem(channel.id, 'fav');
    } else {
      _hiveDb.putData(channel.id, true, 'fav');
    }
    setState(() {
      _updateDisplayedChannels();
      if (_selectedCategoryIndex == 1 &&
          isFav &&
          _focusedChannelNotifier.value == channel) {
        _focusedChannelNotifier.value = _displayedChannels.isNotEmpty
            ? _displayedChannels.first
            : null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusCurrentOrFirstChannel();
        });
      } else if (_focusedChannelNotifier.value == channel) {
        _focusedChannelNotifier.value = null;
        _focusedChannelNotifier.value = channel;
      }
    });
  }

  void _showChannelOptionsDialog(ChannelEntity channel) {
    final displayed = _displayedChannels;
    showDialog(
      context: context,
      builder: (context) => ChannelOptionsDialog(
        channel: channel,
        isFavorite: _isFavorite(channel),
        onToggleFavorite: () => _toggleFavorite(channel),
        onPlay: () {
          widget.onChannelSelected(channel, displayed, _selectedCategoryIndex);
          setState(() {
            currentChannel = channel;
          });
        },
      ),
    );
  }

  void _onCategorySelect(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
      _updateDisplayedChannels();
      if (_displayedChannels.isNotEmpty) {
        final hasCurrent =
            _displayedChannels.any((c) => c.id == currentChannel.id);
        _focusedChannelNotifier.value =
            hasCurrent ? currentChannel : _displayedChannels.first;
      } else {
        _focusedChannelNotifier.value = null;
      }
    });
  }

  /// Transfer focus from Grid into Sidebar
  void _enterSidebar() {
    _sidebarKey.currentState?.focusActiveCategory();
  }

  /// Transfer focus from Sidebar back to Grid
  void _exitSidebarToGrid({int? newCategoryIndex}) {
    if (newCategoryIndex != null &&
        newCategoryIndex != _selectedCategoryIndex) {
      _onCategorySelect(newCategoryIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusCurrentOrFirstChannel();
      });
    } else {
      _focusCurrentOrFirstChannel();
    }
  }

  /// Focus either the currently active channel or first channel in the grid
  void _focusCurrentOrFirstChannel() {
    if (_displayedChannels.isEmpty) {
      _emptyStateFocusNode.requestFocus();
      return;
    }

    final active = _focusedChannelNotifier.value ?? currentChannel;
    final target = _displayedChannels.any((c) => c.id == active.id)
        ? active
        : _displayedChannels.first;

    final targetNode = _getTileFocusNode(target.id);
    if (targetNode.canRequestFocus && targetNode.context != null) {
      targetNode.requestFocus();
      _focusedChannelNotifier.value = target;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (targetNode.canRequestFocus && targetNode.context != null) {
          targetNode.requestFocus();
          _focusedChannelNotifier.value = target;
        } else {
          final first = _displayedChannels.first;
          final firstNode = _getTileFocusNode(first.id);
          firstNode.requestFocus();
          _focusedChannelNotifier.value = first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedChannels;

    return PopScope(
      canPop: !_isSidebarOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSidebarOpen) {
          // If Back pressed while inside the sidebar, safely return to grid
          _exitSidebarToGrid();
        } else if (didPop) {
          widget.onPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Row(
          children: [
            // COLLAPSIBLE SIDEBAR
            CollapsibleSidebar(
              key: _sidebarKey,
              selectedCategoryIndex: _selectedCategoryIndex,
              onExpansionChanged: (open) {
                if (_isSidebarOpen != open) {
                  setState(() => _isSidebarOpen = open);
                }
              },
              onCategorySelected: _onCategorySelect,
              onExitRightFromCategory: (catIndex) {
                _exitSidebarToGrid(newCategoryIndex: catIndex);
              },
              onExitRightFromAction: () {
                _exitSidebarToGrid();
              },
              onSettingsPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      onJioLoginSuccess: () {
                        widget.onJioLoginSuccess?.call();
                      },
                    ),
                  ),
                );
              },
            ),

            // MAIN CONTENT (TOP CHANNEL PREVIEW & CHANNEL GRID)
            Expanded(
              child: Column(
                children: [
                  // TOP CHANNEL PREVIEW HEADER - SOLID DARK SURFACE
                  ValueListenableBuilder<ChannelEntity?>(
                    valueListenable: _focusedChannelNotifier,
                    builder: (context, activeChannel, child) {
                      if (activeChannel == null) {
                        return const SizedBox(height: 200);
                      }

                      return Container(
                        height: 200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28.0,
                          vertical: 20.0,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.black,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF161822),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Channel Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    activeChannel.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.almondSilk,
                                      fontSize: 28,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10121A),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFF1E212D),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.fiber_manual_record,
                                              color: AppColors.lightBronze,
                                              size: 8,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              "LIVE",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                color: AppColors.almondSilk,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (activeChannel.group.isNotEmpty) ...[
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10121A),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: const Color(0xFF1E212D),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            activeChannel.group,
                                            style: const TextStyle(
                                              color: AppColors.lightBronze,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (_isFavorite(activeChannel)) ...[
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10121A),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: const Color(0xFF1E212D),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: AppColors.lightBronze,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "Favorite",
                                                style: TextStyle(
                                                  color: AppColors.lightBronze,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 28),
                            // Channel Logo Card Preview
                            Container(
                              width: 240,
                              height: 140,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C0E14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF1E212D),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CachedNetworkImage(
                                      imageUrl: activeChannel.image,
                                      fit: BoxFit.contain,
                                      memCacheWidth: 400,
                                      fadeInDuration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      placeholder: (context, url) => const Icon(
                                        Icons.tv_rounded,
                                        size: 60,
                                        color: AppColors.claySoil,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.tv_rounded,
                                            size: 60,
                                            color: AppColors.claySoil,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // GRID OF CHANNELS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: displayed.isEmpty
                          ? Focus(
                              focusNode: _emptyStateFocusNode,
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.arrowLeft) {
                                  _enterSidebar();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 56,
                                      color: AppColors.claySoil.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "No channels found in this category",
                                      style: TextStyle(
                                        color: AppColors.lightBronze,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              // ignore: deprecated_member_use
                              cacheExtent: 800.0,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 16 / 9.5,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final channel = displayed[index];
                                final isLeftEdge = index % 4 == 0;
                                final node = _getTileFocusNode(channel.id);

                                final isAutofocus =
                                    !_hasInitiallyAutofocused &&
                                    (channel.id == currentChannel.id ||
                                        (index == 0 &&
                                            !displayed.any(
                                              (c) => c.id == currentChannel.id,
                                            )));

                                return ChannelGridTile(
                                  key: ValueKey(channel.id),
                                  channel: channel,
                                  focusNode: node,
                                  isFavorite: _isFavorite(channel),
                                  isPlaying: channel == currentChannel,
                                  autofocus: isAutofocus,
                                  onFocus: () {
                                    _focusedChannelNotifier.value = channel;
                                  },
                                  onExitLeft: isLeftEdge ? _enterSidebar : null,
                                  onTap: () {
                                    widget.onChannelSelected(
                                      channel,
                                      displayed,
                                      _selectedCategoryIndex,
                                    );
                                    setState(() {
                                      currentChannel = channel;
                                    });
                                  },
                                  onLongPress: () =>
                                      _showChannelOptionsDialog(channel),
                                  onToggleFavorite: () =>
                                      _toggleFavorite(channel),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CHANNEL GRID TILE - CRISP SOLID SURFACES & HAIRLINE EDGES
// ---------------------------------------------------------------------------
class ChannelGridTile extends StatefulWidget {
  final ChannelEntity channel;
  final FocusNode focusNode;
  final bool isFavorite;
  final bool isPlaying;
  final bool autofocus;
  final VoidCallback onFocus;
  final VoidCallback? onExitLeft;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;

  const ChannelGridTile({
    super.key,
    required this.channel,
    required this.focusNode,
    required this.isFavorite,
    required this.isPlaying,
    required this.autofocus,
    required this.onFocus,
    this.onExitLeft,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
  });

  @override
  State<ChannelGridTile> createState() => _ChannelGridTileState();
}

class _ChannelGridTileState extends State<ChannelGridTile> {
  bool _isFocused = false;
  Timer? _longPressTimer;
  bool _isSelectPressed = false;
  bool _isLongPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant ChannelGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _cancelLongPress();
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = widget.focusNode.hasFocus;
    if (mounted && _isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
      });
    }
    if (!hasFocus) {
      _cancelLongPress();
    } else {
      widget.onFocus();
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isSelectPressed = false;
    _isLongPressTriggered = false;
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
    return RepaintBoundary(
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Left arrow on the leftmost column transitions focus into the sidebar
            if (widget.onExitLeft != null &&
                event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              widget.onExitLeft!();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyF ||
                event.logicalKey == LogicalKeyboardKey.asterisk) {
              widget.onToggleFavorite();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                event.logicalKey == LogicalKeyboardKey.keyM) {
              HapticFeedback.mediumImpact();
              widget.onLongPress();
              return KeyEventResult.handled;
            } else if (_isSelectKey(event.logicalKey)) {
              if (!_isSelectPressed) {
                _isSelectPressed = true;
                _isLongPressTriggered = false;
                _longPressTimer?.cancel();
                _longPressTimer = Timer(const Duration(milliseconds: 500), () {
                  if (mounted && widget.focusNode.hasFocus) {
                    _isLongPressTriggered = true;
                    HapticFeedback.mediumImpact();
                    widget.onLongPress();
                  }
                });
              }
              return KeyEventResult.handled;
            }
          } else if (event is KeyRepeatEvent) {
            if (_isSelectKey(event.logicalKey)) {
              return KeyEventResult.handled;
            }
          } else if (event is KeyUpEvent) {
            if (_isSelectKey(event.logicalKey)) {
              final timerWasActive = _longPressTimer?.isActive ?? false;
              _cancelLongPress();
              if (!_isLongPressTriggered && timerWasActive) {
                widget.focusNode.requestFocus();
                widget.onTap();
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            widget.focusNode.requestFocus();
            widget.onTap();
          },
          onLongPress: () {
            widget.focusNode.requestFocus();
            HapticFeedback.mediumImpact();
            widget.onLongPress();
          },
          onSecondaryTap: () {
            widget.focusNode.requestFocus();
            widget.onLongPress();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _isFocused ? 1.05 : 1.0,
              _isFocused ? 1.05 : 1.0,
              1.0,
            ),
            decoration: BoxDecoration(
              color: _isFocused
                  ? const Color(0xFF141622)
                  : const Color(0xFF0C0E14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused
                    ? AppColors.lightBronze
                    : (widget.isPlaying
                          ? AppColors.lightBronze
                          : const Color(0xFF1A1C26)),
                width: _isFocused ? 2.5 : (widget.isPlaying ? 2 : 1),
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.lightBronze.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Logo Background
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.channel.image,
                    fit: BoxFit.contain,
                    memCacheWidth: 200,
                    fadeInDuration: const Duration(milliseconds: 150),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) => const Icon(
                      Icons.tv_rounded,
                      size: 40,
                      color: AppColors.claySoil,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.tv_rounded,
                      size: 40,
                      color: AppColors.claySoil,
                    ),
                  ),
                ),
                // Gradient Overlay for text
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.black.withValues(alpha: 0.92),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.48],
                    ),
                  ),
                ),
                // Title & Favorite Icon
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.channel.name,
                          style: const TextStyle(
                            color: AppColors.almondSilk,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: widget.isFavorite
                            ? const Padding(
                                key: ValueKey("fav_star"),
                                padding: EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: AppColors.lightBronze,
                                  size: 16,
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey("no_fav")),
                      ),
                    ],
                  ),
                ),
                // Playing Indicator
                if (widget.isPlaying)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richMahogany,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.lightBronze,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 12,
                            color: AppColors.almondSilk,
                          ),
                          SizedBox(width: 2),
                          Text(
                            "NOW",
                            style: TextStyle(
                              color: AppColors.almondSilk,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
