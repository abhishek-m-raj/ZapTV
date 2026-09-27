import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/core/widgets/tv_focusable_button.dart';

class ChannelOptionsDialog extends StatefulWidget {
  final ChannelEntity channel;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onPlay;

  const ChannelOptionsDialog({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onPlay,
  });

  @override
  State<ChannelOptionsDialog> createState() => _ChannelOptionsDialogState();
}

class _ChannelOptionsDialogState extends State<ChannelOptionsDialog> {
  late bool _isFavorite;
  bool _ready = false;
  late final FocusNode _favButtonFocusNode;
  late final FocusNode _playButtonFocusNode;
  Timer? _activationTimer;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _favButtonFocusNode = FocusNode();
    _playButtonFocusNode = FocusNode();

    // Since this dialog was opened via long-press, the user is likely still
    // holding down the trigger key on remote or keyboard.
    // Listen for the key-up event before focusing and enabling activation.
    HardwareKeyboard.instance.addHandler(_handleInitialKeyUp);
    _activationTimer = Timer(
      const Duration(milliseconds: 400),
      _enableActivation,
    );
  }

  bool _handleInitialKeyUp(KeyEvent event) {
    if (event is KeyUpEvent) {
      _enableActivation();
    }
    return false;
  }

  void _enableActivation() {
    _activationTimer?.cancel();
    _activationTimer = null;
    HardwareKeyboard.instance.removeHandler(_handleInitialKeyUp);
    if (mounted && !_ready) {
      setState(() {
        _ready = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _favButtonFocusNode.canRequestFocus) {
          _favButtonFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleInitialKeyUp);
    _favButtonFocusNode.dispose();
    _playButtonFocusNode.dispose();
    super.dispose();
  }

  void _handleToggleFavorite() {
    if (!_ready) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });
    Navigator.of(context).pop();
    widget.onToggleFavorite();
  }

  void _handlePlay() {
    if (!_ready) return;
    Navigator.of(context).pop();
    widget.onPlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Listener(
        // Pointer (mouse click / touch tap) interactions activate immediately
        onPointerDown: (_) => _enableActivation(),
        child: Focus(
          onKeyEvent: (node, event) {
            // Swallow key repeats so holding down a key never triggers actions
            if (event is KeyRepeatEvent) {
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.keyF ||
                  event.logicalKey == LogicalKeyboardKey.asterisk) {
                _handleToggleFavorite();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Channel Header (Logo + Info)
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.channel.image,
                        fit: BoxFit.contain,
                        memCacheWidth: 150,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (context, url) => const Icon(
                          Icons.tv,
                          size: 32,
                          color: Colors.white24,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.tv,
                          size: 32,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.channel.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "LIVE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.channel.group,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white60,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                // Favorite Button
                TvFocusableButton(
                  focusNode: _favButtonFocusNode,
                  onPressed: _handleToggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  label: Text(
                    _isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // Play Channel Button
                TvFocusableButton(
                  focusNode: _playButtonFocusNode,
                  onPressed: _handlePlay,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    "Play Channel",
                    style: TextStyle(color: Colors.white),
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
