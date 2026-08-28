import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zaptv/app/home/view/pages/home.dart';
import 'package:zaptv/core/config/locator.dart';

final shortcuts = {
  // 🖥️ TV-specific shortcuts
  ...{
    LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
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

void disableCudaHwdec() {
  if (Platform.isLinux) {
    try {
      final stdlib = DynamicLibrary.process();
      final setenv = stdlib.lookupFunction<
          Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
          int Function(Pointer<Utf8>, Pointer<Utf8>, int)>('setenv');
      final key = 'NVDEC_DISABLE'.toNativeUtf8();
      final val = '1'.toNativeUtf8();
      setenv(key, val, 1);
      calloc.free(key);
      calloc.free(val);
    } catch (_) {}
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  disableCudaHwdec();
  configTouchDevices();
  setupLocator();
  try {
    WakelockPlus.enable();
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
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
}

class ZapTV extends StatelessWidget {
  const ZapTV({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZapTV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.blue,
        ),
      ),
      shortcuts: shortcuts,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    ).animate().fadeIn();
  }
}
