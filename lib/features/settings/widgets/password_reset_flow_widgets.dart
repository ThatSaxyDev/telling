import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:telling_logger/telling_logger.dart';
import '../../../core/config/api_config.dart';
import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../core/utils/text_formatters.dart';
import '../../../shared/widgets/app_button.dart';

/// Step 1: Email Confirmation Dialog
class EmailConfirmationDialog extends ConsumerStatefulWidget {
  final String email;
  final Function(String userId) onOtpSent;

  const EmailConfirmationDialog({
    super.key,
    required this.email,
    required this.onOtpSent,
  });

  @override
  ConsumerState<EmailConfirmationDialog> createState() =>
      _EmailConfirmationDialogState();
}

class _EmailConfirmationDialogState
    extends ConsumerState<EmailConfirmationDialog> {
  bool _isLoading = false;
  String? _error;

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authPath}/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final userId = data['userId'] as String;

        Telling.instance.event(
          'Action: Password Reset OTP Requested',
          properties: {'email': widget.email},
        );

        Navigator.of(context).pop();
        widget.onOtpSent(userId);
      } else if (mounted) {
        setState(() {
          _error = 'Failed to send OTP';
          _isLoading = false;
        });
      }
    } on RateLimitException catch (e) {
      if (mounted) {
        setState(() {
          _error = '${e.message} Retry in ${e.retryAfterFormatted}.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorFormatter.format(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_reset, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(
                  'RESET PASSWORD',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'A ONE-TIME PASSWORD will be sent to:',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isLoading ? 'SENDING...' : 'SEND OTP',
                icon: _isLoading ? null : Icons.send,
                onPressed: _isLoading ? null : _sendOtp,
                backgroundColor: AppColors.secondary.withAlpha(26),
                borderColor: AppColors.secondary,
                foregroundColor: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(
                  'CANCEL',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2: OTP Verification Dialog
class OtpVerificationDialog extends ConsumerStatefulWidget {
  final String userId;
  final String email;
  final Function(String resetToken) onVerified;

  const OtpVerificationDialog({
    super.key,
    required this.userId,
    required this.email,
    required this.onVerified,
  });

  @override
  ConsumerState<OtpVerificationDialog> createState() =>
      _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends ConsumerState<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authPath}/verify-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId, 'otp': _otpController.text}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final resetToken = data['resetToken'] as String;

        Telling.instance.event(
          'Action: Password Reset OTP Verified',
          properties: {'userId': widget.userId},
        );

        Navigator.of(context).pop();
        widget.onVerified(resetToken);
      } else if (mounted) {
        setState(() {
          _error = 'Invalid or expired OTP';
          _isLoading = false;
        });
      }
    } on RateLimitException catch (e) {
      if (mounted) {
        // Check if account is locked
        if (e.message.toLowerCase().contains('locked')) {
          // Show lockout dialog
          Navigator.of(context).pop(); // Close OTP dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Row(
                children: const [
                  Icon(Icons.lock_outline, color: AppColors.error),
                  SizedBox(width: 12),
                  Text(
                    'ACCOUNT LOCKED',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              content: Text(
                '${e.message}\n\nThis is a security measure to protect your account.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _error = '${e.message} Retry in ${e.retryAfterFormatted}.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorFormatter.format(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authPath}/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? 'OTP_RESENT_SUCCESSFULLY'
                  : 'FAILED_TO_RESEND_OTP',
              style: const TextStyle(fontFamily: 'Urbanist'),
            ),
            backgroundColor: response.statusCode == 200
                ? AppColors.secondary
                : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'FAILED_TO_RESEND_OTP',
              style: TextStyle(fontFamily: 'Urbanist'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'VERIFY OTP',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ENTER_CODE_SENT_TO: ${widget.email}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(26),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              TextFormField(
                controller: _otpController,
                enableInteractiveSelection: false,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.white,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                cursorColor: AppColors.secondary,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                maxLength: 8,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'A3X7K9P2',
                  hintStyle: TextStyle(color: AppColors.slate.withAlpha(128)),
                  filled: true,
                  fillColor: AppColors.primary.withAlpha(77),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: AppColors.slate.withAlpha(77),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: AppColors.slate.withAlpha(77),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'REQUIRED_FIELD';
                  }
                  if (value.length != 8) {
                    return 'CODE_MUST_BE_8_CHARACTERS';
                  }
                  if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(value.toUpperCase())) {
                    return 'CODE_MUST_BE_ALPHANUMERIC';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _isLoading ? 'VERIFYING...' : 'VERIFY',
                  icon: _isLoading ? null : Icons.check,
                  onPressed: _isLoading ? null : _verifyOtp,
                  backgroundColor: AppColors.white.withAlpha(26),
                  borderColor: AppColors.white,
                  foregroundColor: AppColors.white,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    'RESEND_CODE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3: New Password Dialog
class NewPasswordDialog extends ConsumerStatefulWidget {
  final String resetToken;

  const NewPasswordDialog({super.key, required this.resetToken});

  @override
  ConsumerState<NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends ConsumerState<NewPasswordDialog> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'REQUIRED_FIELD';
    }
    if (value.length < 8) {
      return 'PASSWORD_MUST_BE_AT_LEAST_8_CHARACTERS';
    }
    if (!RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'PASSWORD_MUST_CONTAIN_NUMBER_OR_SPECIAL_CHAR';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authPath}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resetToken': widget.resetToken,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        Telling.instance.event('Action: Password Reset Successfully');

        Navigator.of(context).pop(true); // Return success
      } else if (mounted) {
        setState(() {
          _error = 'Failed to reset password';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorFormatter.format(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.vpn_key, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Text(
                    'NEW PASSWORD',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(26),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _buildPasswordField(
                label: 'NEW PASSWORD',
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: 'CONFIRM PASSWORD',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'PASSWORDS_DO_NOT_MATCH';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '• Min 8 characters\n• Include number or special character',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _isLoading ? 'RESETTING...' : 'RESET PASSWORD',
                  icon: _isLoading ? null : Icons.check_circle,
                  onPressed: _isLoading ? null : _resetPassword,
                  backgroundColor: AppColors.secondary.withAlpha(26),
                  borderColor: AppColors.secondary,
                  foregroundColor: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.slate,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
          ),
          cursorColor: AppColors.secondary,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.primary.withAlpha(77),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.slate,
                size: 18,
              ),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.white),
            ),
          ),
          validator: validator ?? _validatePassword,
        ),
      ],
    );
  }
}
