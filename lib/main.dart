import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zaptv/app/home/view/pages/home.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:get_it/get_it.dart';
import 'package:zaptv/core/theme/app_theme.dart';

final shortcuts = {
  // 🖥️ TV-specific shortcuts
  ...{
    LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
    // LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
    // LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(
      TraversalDirection.left,
    ),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(
      TraversalDirection.right,
    ),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(
      TraversalDirection.down,
    ),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
      TraversalDirection.up,
    ),
  },
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  MediaKit.ensureInitialized();
  configTouchDevices();
  await setupLocator();
  await GetIt.instance.allReady();
  try {
    await WakelockPlus.enable();
  } catch (_) {}
  runApp(const ZapTV());
}

void configTouchDevices() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class ZapTV extends StatelessWidget {
  const ZapTV({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcuts,
      child: MaterialApp(
        title: 'ZapTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      ),
    );
  }
}
