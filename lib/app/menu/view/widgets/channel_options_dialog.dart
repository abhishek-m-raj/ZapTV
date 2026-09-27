import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/core/theme/app_theme.dart';
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
    return Dialog(
      backgroundColor: AppColors.surfaceDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF1E212D),
          width: 1.0,
        ),
      ),
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
                        color: const Color(0xFF10121A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1E212D),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.channel.image,
                        fit: BoxFit.contain,
                        memCacheWidth: 150,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (context, url) => Icon(
                          Icons.tv,
                          size: 32,
                          color: AppColors.claySoil.withValues(alpha: 0.5),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.tv,
                          size: 32,
                          color: AppColors.claySoil.withValues(alpha: 0.5),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.almondSilk,
                              letterSpacing: 0.2,
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
                                  color: const Color(0xFF10121A),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFF1E212D),
                                  ),
                                ),
                                child: const Text(
                                  "LIVE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: AppColors.almondSilk,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.channel.group,
                                  style: const TextStyle(
                                    color: AppColors.lightBronze,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
                Divider(color: const Color(0xFF1E212D)),
                const SizedBox(height: 16),
                // Favorite Button
                TvFocusableButton(
                  focusNode: _favButtonFocusNode,
                  onPressed: _handleToggleFavorite,
                  icon: Icon(
                    _isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.lightBronze,
                  ),
                  label: Text(
                    _isFavorite ? "Remove from Favorites" : "Add to Favorites",
                  ),
                ),
                const SizedBox(height: 12),
                // Play Channel Button
                TvFocusableButton(
                  focusNode: _playButtonFocusNode,
                  onPressed: _handlePlay,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text("Play Channel"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
