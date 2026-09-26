import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:zaptv/core/services/zap_video_controller.dart';

/// Unified video view widget for ZapTV.
/// Renders media_kit Video on Desktop, BetterPlayer on Android, and video_player VideoPlayer on other Mobile platforms.
class ZapVideoView extends StatelessWidget {
  final ZapVideoController controller;
  final BoxFit fit;

  const ZapVideoView({
    super.key,
    required this.controller,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isDesktop) {
      if (controller.mkVideoController != null) {
        return Video(
          controller: controller.mkVideoController!,
          fit: fit,
          controls: NoVideoControls,
        );
      }
      return const SizedBox.shrink();
    } else {
      return ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isAndroid) {
            final bp = controller.bpController;
            if (bp != null) {
              return BetterPlayer(controller: bp);
            }
          } else {
            final vp = controller.vpController;
            if (vp != null && vp.value.isInitialized) {
              return FittedBox(
                fit: fit,
                child: SizedBox(
                  width: vp.value.size.width,
                  height: vp.value.size.height,
                  child: VideoPlayer(vp),
                ),
              );
            }
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    }
  }
}
