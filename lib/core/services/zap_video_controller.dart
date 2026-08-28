import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:zaptv/core/services/talker_service.dart';

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
      _mkPlayer?.stream.error.listen((err) {
        talker.error('MediaKit Video Error: $err');
      });
      _mkPlayer?.stream.log.listen((log) {
        talker.debug('MediaKit Log: ${log.text}');
      });
    }
  }

  Future<void> open(String url) async {
    if (!url.startsWith('http')) {
      talker.warning('Invalid video stream URL ignored: $url');
      return;
    }

    talker.info('Opening video stream [$engineName]: $url');

    if (isDesktop) {
      try {
        await _mkPlayer?.open(Media(url));
        talker.info('MediaKit video stream command sent successfully');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to open video stream in MediaKit');
      }
    } else {
      final oldController = _vpController;
      _vpController = VideoPlayerController.networkUrl(Uri.parse(url));
      notifyListeners();

      try {
        await _vpController?.initialize();
        await _vpController?.setLooping(true);
        await _vpController?.play();
        talker.info('VideoPlayer mobile stream initialized and playing');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to initialize mobile VideoPlayer');
      }

      await oldController?.dispose();
      notifyListeners();
    }
  }

  String get engineName => isDesktop ? 'MediaKit (Desktop)' : 'VideoPlayer (Mobile)';

  @override
  void dispose() {
    talker.info('Disposing ZapVideoController ($engineName)');
    _mkPlayer?.dispose();
    _vpController?.dispose();
    super.dispose();
  }
}
