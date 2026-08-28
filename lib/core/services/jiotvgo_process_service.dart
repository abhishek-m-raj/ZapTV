import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:zaptv/core/ffi/jiotv_go_ffi.dart';
import 'package:zaptv/core/services/talker_service.dart';

/// Pure FFI manager for the JioTV-Go server.
class JiotvGoProcessService {
  static const String baseUrl = 'http://localhost:5001';
  static const Duration _startupWait = Duration(seconds: 3);

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
      final result = _ffi.startServer(port: '5001', dataDir: dataDir);
      if (result == 0) {
        talker.info('[JioTV FFI] Server started successfully, waiting for port binding...');
        await Future.delayed(_startupWait);
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
  Future<bool> isLoggedIn() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/channels'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) return true;
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

    if (_ffi.isLoaded) {
      final res = _ffi.sendOtp(formatted);
      if (res == 0) {
        return {'success': true, 'message': 'OTP sent successfully'};
      }
      final err = _ffi.getLastError();
      if (err != null && err.isNotEmpty) {
        return {'success': false, 'message': err};
      }
    }

    return {
      'success': false,
      'message': 'Failed to send OTP. Please check mobile number.',
    };
  }

  Future<Map<String, dynamic>> verifyOtp(
      String mobileNumber, String otp) async {
    final formatted = _formatMobile(mobileNumber);

    if (_ffi.isLoaded) {
      final res = _ffi.verifyOtp(formatted, otp);
      if (res == 0) {
        return {'success': true, 'message': 'OTP verified successfully'};
      }
      final err = _ffi.getLastError();
      if (err != null && err.isNotEmpty) {
        return {'success': false, 'message': err};
      }
    }

    return {
      'success': false,
      'message': 'Failed to verify OTP. Please check the code.',
    };
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
