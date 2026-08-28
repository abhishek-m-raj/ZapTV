import 'package:flutter/material.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';

class JiotvLoginDialog extends StatefulWidget {
  const JiotvLoginDialog({super.key});

  @override
  State<JiotvLoginDialog> createState() => _JiotvLoginDialogState();
}

class _JiotvLoginDialogState extends State<JiotvLoginDialog> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  bool _alreadyLoggedIn = false;
  bool _showForm = false;

  late final JiotvGoProcessService _processService;

  @override
  void initState() {
    _processService = loc<JiotvGoProcessService>();
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final loggedIn = await _processService.isLoggedIn();
    if (mounted) {
      setState(() {
        _alreadyLoggedIn = loggedIn;
      });
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      setState(() {
        _statusMessage = 'Please enter a valid 10-digit Jio mobile number.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final res = await _processService.sendOtp(mobile);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = res['success'] == true;
        _statusMessage = res['message'];
        if (_isSuccess) {
          _otpSent = true;
        }
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() {
        _statusMessage = 'Please enter the received OTP.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final res = await _processService.verifyOtp(mobile, otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = res['success'] == true;
        _statusMessage = res['message'];
      });

      if (_isSuccess) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alreadyLoggedIn && !_showForm) {
      return AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('JioTV Active Session'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'You are already logged in to JioTV!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Session credentials are automatically saved in app storage and auto-refreshed in the background. You do NOT need to log in again.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showForm = true;
              });
            },
            child: const Text('Re-authenticate / Change Number'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.tv, color: Colors.blue),
          SizedBox(width: 8),
          Text('JioTV Authentication'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authenticate with your Jio number to enable JioTV live channels.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (!_otpSent) ...[
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Jio Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ] else ...[
              Text(
                'OTP sent to +91 ${_mobileController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _isSuccess ? Colors.green : Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (!_otpSent)
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            child: const Text('Send OTP'),
          )
        else
          ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            child: const Text('Verify OTP'),
          ),
      ],
    );
  }
}
