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
  bool _canActivate = false;
  late final FocusNode _favButtonFocusNode;
  Timer? _activationTimer;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _favButtonFocusNode = FocusNode();

    // Guard against the long-press gesture/key event that triggered this dialog.
    // Delay focus and activation so the key-release or key-repeat does not immediately
    // trigger the button.
    _activationTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _canActivate = true;
        });
        _favButtonFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    _favButtonFocusNode.dispose();
    super.dispose();
  }

  bool get _isKeyReleased {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return !keys.contains(LogicalKeyboardKey.select) &&
        !keys.contains(LogicalKeyboardKey.enter) &&
        !keys.contains(LogicalKeyboardKey.numpadEnter) &&
        !keys.contains(LogicalKeyboardKey.space) &&
        !keys.contains(LogicalKeyboardKey.gameButtonA);
  }

  void _handleToggleFavorite() {
    if (!_canActivate || !_isKeyReleased) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onToggleFavorite();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handlePlay() {
    if (!_canActivate || !_isKeyReleased) return;
    Navigator.of(context).pop();
    widget.onPlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    placeholder: (context, url) =>
                        const Icon(Icons.tv, size: 32, color: Colors.white24),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.tv, size: 32, color: Colors.white24),
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
            // Favorite Button (focused after short debounce to avoid key-leak)
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
    );
  }
}
