import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

/// Unified video controller for ZapTV.
/// Uses media_kit on Desktop (Linux, Windows, macOS) and video_player on Mobile (Android, iOS).
class ZapVideoController extends ChangeNotifier {
  Player? _mkPlayer;
  VideoController? _mkVideoController;
  VideoPlayerController? _vpController;

  bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  Player? get mkPlayer => _mkPlayer;
  VideoController? get mkVideoController => _mkVideoController;
  VideoPlayerController? get vpController => _vpController;

  ZapVideoController() {
    if (isDesktop) {
      _mkPlayer = Player();
      _mkVideoController = VideoController(_mkPlayer!);
    }
  }

  Future<void> open(String url) async {
    if (!url.startsWith('http')) return;

    if (isDesktop) {
      await _mkPlayer?.open(Media(url));
    } else {
      final oldController = _vpController;
      _vpController = VideoPlayerController.networkUrl(Uri.parse(url));
      notifyListeners();

      try {
        await _vpController?.initialize();
        await _vpController?.setLooping(true);
        await _vpController?.play();
      } catch (_) {}

      await oldController?.dispose();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mkPlayer?.dispose();
    _vpController?.dispose();
    super.dispose();
  }
}
