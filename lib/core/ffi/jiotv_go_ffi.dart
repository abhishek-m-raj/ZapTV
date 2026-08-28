import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Dart FFI bindings for the JioTV-Go shared library (libjiotv_go.so/.dylib/.dll).
///
/// The Go bridge exposes these C functions:
///   int JioTVGoStartServer(char* port, char* dataDir)
///   void JioTVGoStopServer()
///   int JioTVGoIsRunning()
///   char* JioTVGoGetLastError()
///   void JioTVGoFreeString(char* str)

// C function typedefs (native signatures)
typedef _StartServerNative = Int32 Function(Pointer<Utf8> port, Pointer<Utf8> dataDir);
typedef _StopServerNative = Void Function();
typedef _IsRunningNative = Int32 Function();
typedef _GetLastErrorNative = Pointer<Utf8> Function();
typedef _FreeStringNative = Void Function(Pointer<Utf8> str);

// Dart function typedefs (mapped signatures)
typedef _StartServerDart = int Function(Pointer<Utf8> port, Pointer<Utf8> dataDir);
typedef _StopServerDart = void Function();
typedef _IsRunningDart = int Function();
typedef _GetLastErrorDart = Pointer<Utf8> Function();
typedef _FreeStringDart = void Function(Pointer<Utf8> str);

typedef _SendOTPNative = Int32 Function(Pointer<Utf8> number);
typedef _SendOTPDart = int Function(Pointer<Utf8> number);
typedef _VerifyOTPNative = Int32 Function(Pointer<Utf8> number, Pointer<Utf8> otp);
typedef _VerifyOTPDart = int Function(Pointer<Utf8> number, Pointer<Utf8> otp);

class JiotvGoFfi {
  late final DynamicLibrary _lib;
  late final _StartServerDart _startServer;
  late final _StopServerDart _stopServer;
  late final _IsRunningDart _isRunning;
  late final _GetLastErrorDart _getLastError;
  late final _FreeStringDart _freeString;
  _SendOTPDart? _sendOtp;
  _VerifyOTPDart? _verifyOtp;

  bool _loaded = false;

  /// Whether the native library was successfully loaded.
  bool get isLoaded => _loaded;

  /// Attempts to load the JioTV-Go shared library.
  /// Returns true if loaded successfully, false otherwise.
  bool load([String? customPath]) {
    if (_loaded) return true;

    try {
      final libPath = customPath ?? _resolveLibraryPath();
      if (libPath == null) return false;

      _lib = DynamicLibrary.open(libPath);

      _startServer = _lib
          .lookupFunction<_StartServerNative, _StartServerDart>('JioTVGoStartServer');
      _stopServer = _lib
          .lookupFunction<_StopServerNative, _StopServerDart>('JioTVGoStopServer');
      _isRunning = _lib
          .lookupFunction<_IsRunningNative, _IsRunningDart>('JioTVGoIsRunning');
      _getLastError = _lib
          .lookupFunction<_GetLastErrorNative, _GetLastErrorDart>('JioTVGoGetLastError');
      _freeString = _lib
          .lookupFunction<_FreeStringNative, _FreeStringDart>('JioTVGoFreeString');

      try {
        _sendOtp = _lib
            .lookupFunction<_SendOTPNative, _SendOTPDart>('JioTVGoSendOTP');
        _verifyOtp = _lib
            .lookupFunction<_VerifyOTPNative, _VerifyOTPDart>('JioTVGoVerifyOTP');
      } catch (_) {}

      _loaded = true;
      return true;
    } catch (_) {
      _loaded = false;
      return false;
    }
  }

  /// Starts the JioTV-Go server on the given [port] with data stored in [dataDir].
  /// Returns 0 on success, -1 on error.
  int startServer({String port = '5001', required String dataDir}) {
    if (!_loaded) return -1;

    final portPtr = port.toNativeUtf8();
    final dataDirPtr = dataDir.toNativeUtf8();

    try {
      return _startServer(portPtr, dataDirPtr);
    } finally {
      calloc.free(portPtr);
      calloc.free(dataDirPtr);
    }
  }

  /// Sends OTP to [number] directly via FFI.
  /// Returns 0 on success, -1 on error.
  int sendOtp(String number) {
    if (!_loaded || _sendOtp == null) return -1;

    final numPtr = number.toNativeUtf8();
    try {
      return _sendOtp!(numPtr);
    } finally {
      calloc.free(numPtr);
    }
  }

  /// Verifies OTP for [number] directly via FFI.
  /// Returns 0 on success, -1 on error.
  int verifyOtp(String number, String otp) {
    if (!_loaded || _verifyOtp == null) return -1;

    final numPtr = number.toNativeUtf8();
    final otpPtr = otp.toNativeUtf8();
    try {
      return _verifyOtp!(numPtr, otpPtr);
    } finally {
      calloc.free(numPtr);
      calloc.free(otpPtr);
    }
  }

  /// Gracefully stops the JioTV-Go server.
  void stopServer() {
    if (!_loaded) return;
    _stopServer();
  }

  /// Returns true if the JioTV-Go server goroutine is currently running.
  bool get isRunning {
    if (!_loaded) return false;
    return _isRunning() == 1;
  }

  /// Returns the last error message from the Go bridge, or null if none.
  String? getLastError() {
    if (!_loaded) return null;

    final ptr = _getLastError();
    if (ptr == nullptr) return null;

    final error = ptr.toDartString();
    _freeString(ptr);
    return error;
  }

  /// Resolves the shared library path based on the current platform.
  String? _resolveLibraryPath() {
    if (Platform.isAndroid) {
      // On Android, .so files bundled in jniLibs are automatically
      // available by name via DynamicLibrary.open
      return 'libjiotv_go.so';
    } else if (Platform.isLinux) {
      // Check next to the executable first, then system lib paths
      final execDir = File(Platform.resolvedExecutable).parent.path;
      final candidates = [
        '$execDir/lib/libjiotv_go.so',
        '$execDir/libjiotv_go.so',
        '/usr/local/lib/libjiotv_go.so',
      ];
      for (final path in candidates) {
        if (File(path).existsSync()) return path;
      }
      return null;
    } else if (Platform.isMacOS) {
      final execDir = File(Platform.resolvedExecutable).parent.path;
      final candidates = [
        '$execDir/../Frameworks/libjiotv_go.dylib',
        '$execDir/libjiotv_go.dylib',
      ];
      for (final path in candidates) {
        if (File(path).existsSync()) return path;
      }
      return null;
    } else if (Platform.isWindows) {
      final execDir = File(Platform.resolvedExecutable).parent.path;
      final candidates = [
        '$execDir\\jiotv_go.dll',
        '$execDir\\lib\\jiotv_go.dll',
      ];
      for (final path in candidates) {
        if (File(path).existsSync()) return path;
      }
      return null;
    }
    return null;
  }
}
