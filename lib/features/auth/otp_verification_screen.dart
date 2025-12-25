import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/funnel_constants.dart';
import '../../core/utils/text_formatters.dart';
import '../../shared/widgets/military_decorations.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String userId;
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Step 5: OTP Verification Screen Viewed (Onboarding Funnel)
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.onboardingFunnel,
      stepName: FunnelConstants.otpVerificationViewed,
      step: 5,
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_formKey.currentState!.validate()) {
      Telling.instance.event(
        'Action: Verify OTP Attempt',
        properties: {'userId': widget.userId},
      );

      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(widget.userId, _otpController.text);

      if (success && mounted) {
        if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
          OneSignal.login(widget.userId);
        }

        Telling.instance.event(
          'Action: Verify OTP Success',
          properties: {'userId': widget.userId},
        );
        // Step 6: OTP Verified (Onboarding Funnel)
        Telling.instance.trackFunnel(
          funnelName: FunnelConstants.onboardingFunnel,
          stepName: FunnelConstants.otpVerified,
          step: 6,
        );
        context.go('/projects');
      } else {
        Telling.instance.event(
          'Action: Verify OTP Failed',
          properties: {'userId': widget.userId},
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    final success = await ref
        .read(authProvider.notifier)
        .resendOtp(widget.userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'OTP_RESENT_SUCCESSFULLY' : 'FAILED_TO_RESEND_OTP',
            style: const TextStyle(fontFamily: 'Urbanist'),
          ),
          backgroundColor: success ? AppColors.secondary : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(
              color: Color(0xFF1A1A1A),
              spacing: 40,
              strokeWidth: 0.5,
            ),
          ),
          Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withAlpha(230),
                border: Border.all(color: AppColors.slate.withAlpha(77)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SECURITY_CHECK // 2FA',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        color: AppColors.white,
                        fontSize: 20,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ENTER_CODE_SENT_TO: ${widget.email}',
                      style: const TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.slate,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (authState.error != null)
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
                              Icons.warning,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontFamily: 'Urbanist',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildTextField(
                      controller: _otpController,
                      label: 'ONE_TIME_PASSWORD',
                      icon: Icons.lock_clock_outlined,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: isMobile ? 44 : 48,
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: authState.isLoading ? null : _verify,
                          child: Center(
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Text(
                                    'VERIFY_IDENTITY',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          'RESEND_CODE',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            color: AppColors.secondary,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'ABORT_VERIFICATION',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            color: AppColors.slate,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.slate,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          enableInteractiveSelection: false,
          controller: controller,
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
            prefixIcon: Icon(icon, color: AppColors.slate, size: 18),
            filled: true,
            fillColor: AppColors.primary.withAlpha(77),
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
      ],
    );
  }
}
