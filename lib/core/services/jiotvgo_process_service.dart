import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:zaptv/core/ffi/jiotv_go_ffi.dart';
import 'package:zaptv/core/services/talker_service.dart';

/// Pure FFI manager for the JioTV-Go server.
class JiotvGoProcessService {
  static const String baseUrl = 'http://localhost:5050';

  final JiotvGoFfi _ffi = JiotvGoFfi();
  bool _isStarting = false;

  /// Whether the server is running via FFI.
  bool get isRunning => _ffi.isRunning;

  /// Initialize and start the JioTV-Go server via FFI.
  Future<void> initAndStart() async {
    if (_isStarting) return;
    _isStarting = true;

    try {
      if (await isServerRunning()) {
        talker.info('[JioTV FFI] Server is already running on $baseUrl');
        return;
      }

      talker.info('[JioTV FFI] Loading shared library libjiotv_go...');
      if (!_ffi.load()) {
        talker.warning('[JioTV FFI] Failed to load libjiotv_go shared library');
        return;
      }

      final dataDir = await _getDataDir();
      talker.info('[JioTV FFI] Starting JioTV-Go server with dataDir=$dataDir');
      final result = _ffi.startServer(port: '5050', dataDir: dataDir);
      if (result == 0) {
        talker.info('[JioTV FFI] Server started successfully, waiting for it to become ready...');
        await _waitForServerReady();
      } else {
        final err = _ffi.getLastError();
        talker.error('[JioTV FFI] Server start error: $err');
      }
    } catch (e, st) {
      talker.handle(e, st, '[JioTV FFI] Initialization failed');
    } finally {
      _isStarting = false;
    }
  }

  /// Ensure the server is running. If not, start it and wait for it to be ready.
  Future<void> ensureRunning() async {
    if (await isServerRunning()) return;
    await initAndStart();
  }

  /// Poll until the server responds or timeout after ~10 seconds.
  Future<void> _waitForServerReady() async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (await isServerRunning()) {
        talker.info('[JioTV FFI] Server is ready after ${i + 1}s');
        return;
      }
    }
    talker.warning('[JioTV FFI] Server did not become ready within 10s');
  }

  /// Returns true if the JioTV-Go HTTP server is reachable.
  Future<bool> isServerRunning() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 2));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the server has a valid authenticated session.
  /// Ensures the server is running before checking.
  Future<bool> isLoggedIn() async {
    try {
      // Make sure the server is actually up before checking login
      await ensureRunning();

      final response = await http
          .get(Uri.parse('$baseUrl/playlist.m3u'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.body.contains('#EXTM3U')) {
        // If the playlist has channels (body length > 100), we are logged in.
        return response.body.length > 100;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _formatMobile(String mobile) {
    var cleaned = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        cleaned = '+91$cleaned';
      } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
        cleaned = '+$cleaned';
      }
    }
    return cleaned;
  }

  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    final formatted = _formatMobile(mobileNumber);
    talker.info('[ProcessService] Sending OTP to $formatted');

    // Bypass FFI because modifying credentials via FFI doesn't update the 
    // running HTTP server's memory. Hit the HTTP server directly.
    final url = '$baseUrl/login/sendOTP';
    talker.info('[ProcessService] Trying HTTP fallback: $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': formatted}),
      ).timeout(const Duration(seconds: 5));
      talker.info('[ProcessService] HTTP response code: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        talker.info('[ProcessService] OTP sent successfully via HTTP fallback');
        return {'success': true, 'message': 'OTP sent successfully'};
      }
    } catch (e, st) {
      talker.error('[ProcessService] HTTP fallback sendOtp failed', e, st);
    }

    return {
      'success': false,
      'message': 'Failed to send OTP. Please check mobile number.',
    };
  }

  Future<Map<String, dynamic>> verifyOtp(
      String mobileNumber, String otp) async {
    final formatted = _formatMobile(mobileNumber);
    talker.info('[ProcessService] Verifying OTP for $formatted (OTP length: ${otp.length})');

    // Bypass FFI because modifying credentials via FFI doesn't update the 
    // running HTTP server's memory. Hit the HTTP server directly.
    final url = '$baseUrl/login/verifyOTP';
    talker.info('[ProcessService] Trying HTTP fallback: $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': formatted, 'otp': otp}),
      ).timeout(const Duration(seconds: 5));
      talker.info('[ProcessService] HTTP response code: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        talker.info('[ProcessService] OTP verified successfully via HTTP fallback');
        return {'success': true, 'message': 'OTP verified successfully'};
      }
    } catch (e, st) {
      talker.error('[ProcessService] HTTP fallback verifyOtp failed', e, st);
    }

    return {
      'success': false,
      'message': 'Failed to verify OTP. Please check the code.',
    };
  }

  /// Restart the server so it reloads credentials from disk.
  /// Needed after login via FFI — the already-running server won't
  /// pick up newly saved credentials without a restart.
  Future<void> restartServer() async {
    talker.info('[JioTV FFI] Restarting server to reload credentials...');
    stopServer();

    // Poll until the server actually stops (up to 5 seconds)
    bool stopped = false;
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!await isServerRunning()) {
        talker.info('[JioTV FFI] Server stopped after ${(i + 1) * 250}ms');
        stopped = true;
        break;
      }
    }

    if (!stopped) {
      talker.warning('[JioTV FFI] Server did not stop within 5s, forcing restart...');
    }

    _isStarting = false; // Reset the guard so initAndStart() can proceed
    await initAndStart();
  }

  void stopServer() {
    _ffi.stopServer();
  }

  Future<String> _getDataDir() async {
    final dir = await getApplicationSupportDirectory();
    final jiotvDir = Directory('${dir.path}/jiotv_go');
    if (!await jiotvDir.exists()) {
      await jiotvDir.create(recursive: true);
    }
    return jiotvDir.path;
  }
}
