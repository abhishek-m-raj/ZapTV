import 'package:flutter/material.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';

/// Minimal overlay displaying only a large centered lock icon when a channel requires a premium subscription.
class PremiumChannelOverlay extends StatelessWidget {
  final ChannelEntity channel;
  final VoidCallback? onOpenMenu;

  const PremiumChannelOverlay({
    super.key,
    required this.channel,
    this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 110,
          color: Colors.amber.shade600,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 24),
          ],
        ),
      ),
    );
  }
}
