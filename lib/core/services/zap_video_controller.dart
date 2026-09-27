import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:zaptv/core/services/talker_service.dart';

/// Unified video controller for ZapTV.
/// Uses media_kit on Desktop (Linux, Windows, macOS), BetterPlayer on Android (for DRM support), and video_player on other Mobile platforms.
class ZapVideoController extends ChangeNotifier {
  Player? _mkPlayer;
  VideoController? _mkVideoController;
  VideoPlayerController? _vpController;
  BetterPlayerController? _bpController;

  void Function(String error)? onPlaybackError;

  bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  Player? get mkPlayer => _mkPlayer;
  VideoController? get mkVideoController => _mkVideoController;
  VideoPlayerController? get vpController => _vpController;
  BetterPlayerController? get bpController => _bpController;

  ZapVideoController() {
    if (isDesktop) {
      _mkPlayer = Player();
      _mkVideoController = VideoController(
        _mkPlayer!,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: !Platform.isLinux,
          hwdec: Platform.isLinux ? 'no' : 'auto',
        ),
      );
      _mkPlayer?.stream.error.listen((err) {
        talker.error('MediaKit Video Error: $err');
        onPlaybackError?.call(err.toString());
      });
      _mkPlayer?.stream.log.listen((log) {
        talker.debug('MediaKit Log: ${log.text}');
        if (log.text.contains('500') ||
            log.text.toLowerCase().contains('server returned 500')) {
          onPlaybackError?.call(log.text);
        }
      });
    }
  }

  Future<void> open(
    String url, {
    String? licenseType,
    String? licenseKey,
  }) async {
    if (!url.startsWith('http')) {
      talker.warning('Invalid video stream URL ignored: $url');
      return;
    }

    talker.info(
      'Opening video stream [$engineName]: $url (License Key: $licenseKey)',
    );

    if (isDesktop) {
      try {
        await _mkPlayer?.open(Media(url));
        talker.info('MediaKit video stream command sent successfully');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to open video stream in MediaKit');
        onPlaybackError?.call(e.toString());
      }
    } else if (isAndroid) {
      final oldController = _bpController;

      final drmConfig = licenseKey != null
          ? BetterPlayerDrmConfiguration(
              drmType: BetterPlayerDrmType.widevine,
              licenseUrl: licenseKey,
            )
          : null;

      BetterPlayerVideoFormat? videoFormat;
      if (url.contains('.m3u8')) {
        videoFormat = BetterPlayerVideoFormat.hls;
      } else if (url.contains('/mpd/') || url.contains('.mpd')) {
        videoFormat = BetterPlayerVideoFormat.dash;
      }

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        videoFormat: videoFormat,
        drmConfiguration: drmConfig,
      );

      _bpController = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: true,
          looping: true,
          fit: BoxFit.contain,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            showControls: false,
          ),
        ),
        betterPlayerDataSource: dataSource,
      );

      _bpController?.addEventsListener((BetterPlayerEvent event) {
        if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
          final errStr = event.parameters?.toString() ?? '';
          talker.error('BetterPlayer exception: $errStr');
          onPlaybackError?.call(errStr);
        }
      });

      notifyListeners();

      try {
        talker.info('BetterPlayer android stream initialized');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to initialize better_player_plus');
        onPlaybackError?.call(e.toString());
      }

      if (oldController != null) {
        oldController.dispose();
      }
      notifyListeners();
    } else {
      final oldController = _vpController;
      _vpController = VideoPlayerController.networkUrl(Uri.parse(url));
      _vpController?.addListener(() {
        if (_vpController != null && _vpController!.value.hasError) {
          final errStr = _vpController!.value.errorDescription ?? '';
          talker.error('VideoPlayer mobile error: $errStr');
          onPlaybackError?.call(errStr);
        }
      });
      notifyListeners();

      try {
        await _vpController?.initialize();
        await _vpController?.setLooping(true);
        await _vpController?.play();
        talker.info('VideoPlayer mobile stream initialized and playing');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to initialize mobile VideoPlayer');
        onPlaybackError?.call(e.toString());
      }

      await oldController?.dispose();
      notifyListeners();
    }
  }

  Future<void> stop() async {
    talker.info('Stopping video stream [$engineName]');
    if (isDesktop) {
      try {
        await _mkPlayer?.stop();
      } catch (_) {}
    } else if (isAndroid) {
      try {
        await _bpController?.pause();
      } catch (_) {}
    } else {
      try {
        await _vpController?.pause();
      } catch (_) {}
    }
    notifyListeners();
  }

  String get engineName {
    if (isDesktop) return 'MediaKit (Desktop)';
    if (isAndroid) return 'BetterPlayer (Android)';
    return 'VideoPlayer (Mobile)';
  }

  @override
  void dispose() {
    talker.info('Disposing ZapVideoController ($engineName)');
    _mkPlayer?.dispose();
    _bpController?.dispose();
    _vpController?.dispose();
    super.dispose();
  }
}
