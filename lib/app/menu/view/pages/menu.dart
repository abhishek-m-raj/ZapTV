import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/app/menu/view/widgets/channel_options_dialog.dart';
import 'package:zaptv/app/menu/view/widgets/jiotv_login_dialog.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/hive_db.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';
import 'package:zaptv/core/widgets/tv_focusable_button.dart';

class MenuPage extends StatefulWidget {
  final ChannelEntity currentChannel;
  final List<ChannelEntity> channels;
  final Function(ChannelEntity, List<ChannelEntity>) onChannelSelected;
  final VoidCallback onPop;
  final VoidCallback? onJioLoginSuccess;

  const MenuPage({
    super.key,
    required this.currentChannel,
    required this.channels,
    required this.onChannelSelected,
    required this.onPop,
    this.onJioLoginSuccess,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late ChannelEntity currentChannel;
  bool _isJioLoggedIn = false;
  int _selectedCategoryIndex = 0; // 0: All, 1: Favorites
  final HiveDb _hiveDb = loc<HiveDb>();

  // To keep track of the currently focused channel in the grid
  ChannelEntity? _focusedChannel;

  @override
  void initState() {
    currentChannel = widget.currentChannel;
    _focusedChannel = currentChannel;
    _checkJioLoginStatus();
    super.initState();
  }

  Future<void> _checkJioLoginStatus() async {
    try {
      final service = loc<JiotvGoProcessService>();
      final loggedIn = await service.isLoggedIn();
      if (mounted) {
        setState(() {
          _isJioLoggedIn = loggedIn;
        });
      }
    } catch (_) {}
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
      if (_selectedCategoryIndex == 1 && isFav && _focusedChannel == channel) {
        final remaining = widget.channels.where((c) => _isFavorite(c)).toList();
        _focusedChannel = remaining.isNotEmpty ? remaining.first : null;
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
          widget.onChannelSelected(channel, displayed);
          setState(() {
            currentChannel = channel;
          });
        },
      ),
    );
  }

  List<ChannelEntity> get _displayedChannels {
    if (_selectedCategoryIndex == 1) {
      return widget.channels.where((c) => _isFavorite(c)).toList();
    } else if (_selectedCategoryIndex == 2) {
      return widget.channels.where((c) => c.id.endsWith('-jiotv')).toList();
    } else if (_selectedCategoryIndex == 3) {
      return widget.channels.where((c) => !c.id.endsWith('-jiotv')).toList();
    }
    return widget.channels;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayed = _displayedChannels;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onPop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Row(
          children: [
            // LEFT NAVIGATION RAIL
            Container(
              width: 260,
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "ZapTV",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _SideMenuItem(
                    icon: Icons.tv,
                    label: "All Channels",
                    isSelected: _selectedCategoryIndex == 0,
                    onFocus: () => setState(() => _selectedCategoryIndex = 0),
                  ),
                  _SideMenuItem(
                    icon: Icons.star,
                    label: "Favorites",
                    isSelected: _selectedCategoryIndex == 1,
                    onFocus: () => setState(() => _selectedCategoryIndex = 1),
                  ),
                  _SideMenuItem(
                    icon: Icons.cell_tower,
                    label: "JioTV",
                    isSelected: _selectedCategoryIndex == 2,
                    onFocus: () => setState(() => _selectedCategoryIndex = 2),
                  ),
                  _SideMenuItem(
                    icon: Icons.public,
                    label: "IPTV",
                    isSelected: _selectedCategoryIndex == 3,
                    onFocus: () => setState(() => _selectedCategoryIndex = 3),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TvFocusableButton(
                      isJioLoggedIn: _isJioLoggedIn,
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const JiotvLoginDialog(),
                        );
                        if (result == true) {
                          _checkJioLoginStatus();
                          widget.onJioLoginSuccess?.call();
                        }
                      },
                      icon: Icon(
                        _isJioLoggedIn ? Icons.check_circle : Icons.login,
                      ),
                      label: Text(
                        _isJioLoggedIn ? "JioTV: Logged In" : "JioTV Login",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // MAIN CONTENT AREA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TOP HEADER / PREVIEW
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surface.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _focusedChannel?.name ?? currentChannel.name,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "LIVE",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _focusedChannel?.group ??
                                        currentChannel.group,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                  if (_isFavorite(
                                    _focusedChannel ?? currentChannel,
                                  )) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 300,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CachedNetworkImage(
                            imageUrl:
                                _focusedChannel?.image ?? currentChannel.image,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Icon(
                              Icons.tv,
                              size: 80,
                              color: Colors.white24,
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.tv,
                              size: 80,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // GRID OF CHANNELS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: displayed.isEmpty
                          ? Center(
                              child: Text(
                                "No channels found.",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 16 / 9,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final channel = displayed[index];
                                return ChannelGridTile(
                                  channel: channel,
                                  isFavorite: _isFavorite(channel),
                                  isPlaying: channel == currentChannel,
                                  autofocus:
                                      channel == currentChannel &&
                                      _selectedCategoryIndex == 0,
                                  onFocus: () {
                                    setState(() {
                                      _focusedChannel = channel;
                                    });
                                  },
                                  onTap: () {
                                    widget.onChannelSelected(
                                      channel,
                                      displayed,
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

class _SideMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onFocus;

  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onFocus,
  });

  @override
  State<_SideMenuItem> createState() => _SideMenuItemState();
}

class _SideMenuItemState extends State<_SideMenuItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.isSelected || _isFocused;

    return InkWell(
      onFocusChange: (val) {
        setState(() => _isFocused = val);
        if (val) widget.onFocus();
      },
      onTap: widget.onFocus,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? theme.colorScheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: active
                  ? theme.colorScheme.onPrimaryContainer
                  : Colors.white60,
            ),
            const SizedBox(width: 16),
            Text(
              widget.label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: active
                    ? theme.colorScheme.onPrimaryContainer
                    : Colors.white60,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChannelGridTile extends StatefulWidget {
  final ChannelEntity channel;
  final bool isFavorite;
  final bool isPlaying;
  final bool autofocus;
  final VoidCallback onFocus;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;

  const ChannelGridTile({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.isPlaying,
    required this.autofocus,
    required this.onFocus,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
  });

  @override
  State<ChannelGridTile> createState() => _ChannelGridTileState();
}

class _ChannelGridTileState extends State<ChannelGridTile> {
  bool _isFocused = false;
  late final FocusNode _focusNode;
  Timer? _longPressTimer;
  bool _isSelectPressed = false;
  bool _isLongPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (!_focusNode.hasFocus) {
        _cancelLongPress();
      }
      if (_focusNode.hasFocus) {
        widget.onFocus();
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isSelectPressed = false;
    _isLongPressTriggered = false;
  }

  @override
  void dispose() {
    _cancelLongPress();
    _focusNode.dispose();
    super.dispose();
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
    final theme = Theme.of(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyF ||
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
                if (mounted && _focusNode.hasFocus) {
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
              _focusNode.requestFocus();
              widget.onTap();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          widget.onTap();
        },
        onLongPress: () {
          _focusNode.requestFocus();
          HapticFeedback.mediumImpact();
          widget.onLongPress();
        },
        onSecondaryTap: () {
          _focusNode.requestFocus();
          widget.onLongPress();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _isFocused ? 1.05 : 1.0,
            _isFocused ? 1.05 : 1.0,
            1.0,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : (widget.isPlaying
                        ? theme.colorScheme.primary
                        : Colors.transparent),
              width: _isFocused ? 3 : (widget.isPlaying ? 2 : 0),
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Logo Background
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CachedNetworkImage(
                  imageUrl: widget.channel.image,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Icon(Icons.tv, size: 40, color: Colors.white24),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.tv, size: 40, color: Colors.white24),
                ),
              ),
              // Gradient Overlay for text
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 0.4],
                  ),
                ),
              ),
              // Title & Favorite Icon
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.channel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: widget.isFavorite
                          ? const Padding(
                              key: ValueKey('fav_star'),
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no_fav')),
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
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 14,
                      color: Colors.white,
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
