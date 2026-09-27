import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zaptv/app/home/domain/entities/channel.dart';
import 'package:zaptv/core/theme/app_theme.dart';

class ChannelInfo extends StatelessWidget {
  final ChannelEntity currentChannel;
  final bool isPremiumError;

  const ChannelInfo({
    super.key,
    required this.currentChannel,
    this.isPremiumError = false,
  });

  String _formatTime(DateTime time) {
    int hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String timeString = _formatTime(DateTime.now());

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.black.withValues(alpha: 0.95),
              AppColors.black.withValues(alpha: 0.70),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: currentChannel.image,
                      fit: BoxFit.contain,
                      memCacheWidth: 200,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (context, url) =>
                          const Icon(Icons.tv, size: 40, color: Colors.grey),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.tv, size: 40, color: Colors.grey),
                    ),
                  ),
                  if (isPremiumError)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.richMahogany,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber.shade600,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            // Channel Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentChannel.group.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richMahogany,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.claySoil.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        currentChannel.group.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.almondSilk,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    currentChannel.name,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.almondSilk,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPremiumError ? "Subscription Required" : "Now Playing",
                    style: TextStyle(
                      color: isPremiumError
                          ? Colors.amber.shade300
                          : AppColors.lightBronze,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Time & LIVE
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeString,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.almondSilk,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "LIVE",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
