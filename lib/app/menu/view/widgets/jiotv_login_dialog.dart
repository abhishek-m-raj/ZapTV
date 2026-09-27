import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaptv/core/config/locator.dart';
import 'package:zaptv/core/services/jiotvgo_process_service.dart';
import 'package:zaptv/core/services/talker_service.dart';
import 'package:zaptv/core/theme/app_theme.dart';
import 'package:zaptv/core/widgets/custom_tv_text_field.dart';
import 'package:zaptv/core/widgets/tv_focusable_button.dart';
import 'package:custom_tv_text_field/custom_tv_text_field.dart';

enum DialogFocus { field, submit, cancel }

class JiotvLoginDialog extends StatefulWidget {
  const JiotvLoginDialog({super.key});

  @override
  State<JiotvLoginDialog> createState() => _JiotvLoginDialogState();
}

class _JiotvLoginDialogState extends State<JiotvLoginDialog> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final GlobalKey<CustomTVTextFieldState> _mobileKey =
      GlobalKey<CustomTVTextFieldState>();
  final GlobalKey<CustomTVTextFieldState> _otpKey =
      GlobalKey<CustomTVTextFieldState>();
  final FocusNode _dialogFocusNode = FocusNode();

  DialogFocus _currentFocus = DialogFocus.field;

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
    _dialogFocusNode.requestFocus();
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
    talker.info('[LoginDialog] Send OTP clicked for mobile: $mobile');
    if (mobile.length != 10) {
      talker.warning('[LoginDialog] Invalid mobile length: ${mobile.length}');
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
    talker.info('[LoginDialog] Send OTP response: $res');

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = res['success'] == true;
        _statusMessage = res['message'];
        if (_isSuccess) {
          _otpSent = true;
          talker.info(
            '[LoginDialog] OTP sent successfully, state set to otpSent=true',
          );
        }
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();
    talker.info(
      '[LoginDialog] Verify OTP clicked for mobile: $mobile, otp length: ${otp.length}',
    );
    if (otp.length < 4) {
      talker.warning('[LoginDialog] Invalid OTP length: ${otp.length}');
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
    talker.info('[LoginDialog] Verify OTP response: $res');

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = res['success'] == true;
        _statusMessage = res['message'];
      });

      if (_isSuccess) {
        talker.info(
          '[LoginDialog] OTP verification successful, restarting server to load credentials...',
        );
        // Restart the server so it picks up the newly saved credentials.
        if (mounted) {
          setState(() {
            _statusMessage = 'Login successful! Starting JioTV server...';
          });
        }
        await _processService.restartServer();
        talker.info('[LoginDialog] Server restarted, closing dialog...');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        talker.warning('[LoginDialog] OTP verification failed');
      }
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_currentFocus == DialogFocus.field) {
          _currentFocus = DialogFocus.submit;
        } else if (_currentFocus == DialogFocus.submit) {
          _currentFocus = DialogFocus.cancel;
        }
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_currentFocus == DialogFocus.cancel) {
          _currentFocus = DialogFocus.submit;
        } else if (_currentFocus == DialogFocus.submit) {
          _currentFocus = DialogFocus.field;
        }
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      if (_currentFocus == DialogFocus.field) {
        if (!_otpSent) {
          _mobileKey.currentState?.toggleKeyboard();
        } else {
          _otpKey.currentState?.toggleKeyboard();
        }
      } else if (_currentFocus == DialogFocus.submit) {
        if (!_otpSent) {
          _handleSendOtp();
        } else {
          _handleVerifyOtp();
        }
      } else if (_currentFocus == DialogFocus.cancel) {
        Navigator.of(context).pop(false);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_alreadyLoggedIn && !_showForm) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF1E212D),
            width: 1.0,
          ),
        ),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.lightBronze),
            SizedBox(width: 10),
            Text(
              'JioTV Active Session',
              style: TextStyle(
                color: AppColors.almondSilk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'You are already logged in to JioTV!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.almondSilk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session credentials are automatically saved in app storage and auto-refreshed in the background. You do NOT need to log in again.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TvFocusableButton(
              onPressed: () => Navigator.of(context).pop(true),
              label: const Text('OK'),
            ),
            const SizedBox(height: 12),
            TvFocusableButton(
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
              label: const Text('Re-authenticate / Change Number'),
            ),
          ],
        ),
      );
    }

    return Focus(
      focusNode: _dialogFocusNode,
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: AlertDialog(
        backgroundColor: AppColors.surfaceDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.claySoil.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        title: Row(
          children: const [
            Icon(Icons.live_tv_rounded, color: AppColors.lightBronze),
            SizedBox(width: 10),
            Text(
              'JioTV Authentication',
              style: TextStyle(
                color: AppColors.almondSilk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Authenticate with your Jio number to enable JioTV live channels.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              if (!_otpSent) ...[
                CustomTvTextField(
                  fieldKey: _mobileKey,
                  isFocused: _currentFocus == DialogFocus.field,
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  labelText: 'Jio Mobile Number',
                  prefixText: '+91 ',
                ),
              ] else ...[
                Text(
                  'OTP sent to +91 ${_mobileController.text}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.almondSilk,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTvTextField(
                  fieldKey: _otpKey,
                  isFocused: _currentFocus == DialogFocus.field,
                  controller: _otpController,
                  keyboardType: TextInputType.text,
                  maxLength: 6,
                  labelText: 'Enter OTP',
                ),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isSuccess
                        ? AppColors.lightBronze
                        : const Color(0xFFCF6679),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.lightBronze,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TvFocusableButton(
                onPressed: _isLoading
                    ? () {}
                    : (!_otpSent ? _handleSendOtp : _handleVerifyOtp),
                isFocused: _currentFocus == DialogFocus.submit,
                label: Text(
                  _isLoading
                      ? 'Processing...'
                      : (!_otpSent ? 'Send OTP' : 'Verify OTP'),
                ),
              ),
              const SizedBox(height: 12),
              TvFocusableButton(
                onPressed: _isLoading
                    ? () {}
                    : () => Navigator.of(context).pop(false),
                isFocused: _currentFocus == DialogFocus.cancel,
                label: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
