import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling/features/settings/widgets/password_reset_flow_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';
import 'package:telling_logger/telling_logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      Telling.instance.event(
        'Action: Login Attempt',
        properties: {'email': _emailController.text},
      );
      final userId = await ref
          .read(authProvider.notifier)
          .login(_emailController.text, _passwordController.text);

      if (mounted && userId != null) {
        Telling.instance.event(
          'Action: Login Success (OTP Sent)',
          properties: {'email': _emailController.text},
        );
        context.go(
          '/verify-otp',
          extra: {'userId': userId, 'email': _emailController.text},
        );
      } else if (mounted) {
        Telling.instance.event(
          'Action: Login Failed',
          properties: {'email': _emailController.text},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
                      'ACCESS_CONTROL // LOGIN',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        color: AppColors.white,
                        fontSize: 20,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
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
                      controller: _emailController,
                      label: 'OPERATOR_ID (EMAIL)',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'ACCESS_CODE (PASSWORD)',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onTogglePasswordVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary,
                                ),
                              )
                            : const Text(
                                'INITIATE_SESSION',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Telling.instance.event(
                            'Interaction: Navigate to Register',
                            properties: {'from': 'LoginScreen'},
                          );
                          context.go('/register');
                        },
                        child: const Text(
                          'REQUEST_CLEARANCE (REGISTER)',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          final value = _emailController.text.trim();
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter your valid email',
                                  style: TextStyle(fontFamily: 'Urbanist'),
                                ),
                                backgroundColor: AppColors.white,
                              ),
                            );
                            return;
                          }

                          Telling.instance.event(
                            'Interaction: Forgot Password',
                            properties: {'from': 'LoginScreen'},
                          );

                          _initiatePasswordReset(context, ref);
                        },
                        child: const Text(
                          'FORGOT_PASSWORD?',
                          style: TextStyle(
                            fontFamily: 'Syne',
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
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
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
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
          ),
          cursorColor: AppColors.secondary,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.slate, size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.slate,
                      size: 18,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  )
                : null,
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
            return null;
          },
        ),
      ],
    );
  }

  void _initiatePasswordReset(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EmailConfirmationDialog(
        email: _emailController.text.trim(),
        onOtpSent: (userId) {
          // Step 2: OTP Verification
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => OtpVerificationDialog(
              userId: userId,
              email: _emailController.text.trim(),
              onVerified: (resetToken) {
                // Step 3: New Password
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) =>
                      NewPasswordDialog(resetToken: resetToken),
                ).then((success) {
                  if (success == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'PASSWORD RESET SUCCESSFULLY',
                          style: TextStyle(fontFamily: 'Urbanist'),
                        ),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}
