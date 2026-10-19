import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling/features/settings/widgets/password_reset_flow_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/constants/funnel_constants.dart';

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
  void initState() {
    super.initState();
    // Step 1: Login Screen Viewed
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.authFunnel,
      stepName: FunnelConstants.loginViewed,
      step: 1,
    );
  }

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

      // Step 2: Login Submitted
      Telling.instance.trackFunnel(
        funnelName: FunnelConstants.authFunnel,
        stepName: FunnelConstants.loginSubmitted,
        step: 2,
        properties: {'email': _emailController.text},
      );

      final userId = await ref
          .read(authProvider.notifier)
          .login(_emailController.text, _passwordController.text);

      // Check if demo login succeeded (userId is null but user is authenticated)
      final authState = ref.read(authProvider);
      if (mounted && userId == null && authState.isAuthenticated) {
        // Demo login succeeded - go directly to projects
        Telling.instance.event(
          'Action: Demo Login Success',
          properties: {'email': _emailController.text},
        );
        context.go('/projects');
        return;
      }

      if (mounted && userId != null) {
        Telling.instance.event(
          'Action: Login Success (OTP Sent)',
          properties: {'email': _emailController.text},
        );

        // Step 3: Login Success
        Telling.instance.trackFunnel(
          funnelName: FunnelConstants.authFunnel,
          stepName: FunnelConstants.loginSuccess,
          step: 3,
          properties: {'userId': userId},
        );

        context.go(
          '/verify-otp',
          extra: {'userId': userId, 'email': _emailController.text},
        );
      } else if (mounted && !authState.isAuthenticated) {
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: isMobile ? 16 : 32,
                ).copyWith(bottom: bottomInset > 0 ? 16 : (isMobile ? 16 : 32)),
                child: Container(
                  width: isMobile ? double.infinity : 400,
                  padding: EdgeInsets.all(isMobile ? 20 : 32),
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
                        Text(
                          isMobile ? 'LOGIN' : 'ACCESS_CONTROL // LOGIN',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            color: AppColors.white,
                            fontSize: isMobile ? 18 : 20,
                            letterSpacing: isMobile ? 1 : 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 32),
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
                        SizedBox(height: isMobile ? 12 : 16),
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
                        SizedBox(height: isMobile ? 24 : 32),
                        SizedBox(
                          width: double.infinity,
                          height: isMobile ? 44 : 48,
                          child: Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: authState.isLoading ? null : _login,
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
                                    : Text(
                                        isMobile ? 'LOGIN' : 'INITIATE_SESSION',
                                        style: const TextStyle(
                                          fontFamily: 'Urbanist',
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontSize: 14,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Telling.instance.event(
                                'Interaction: Navigate to Register',
                                properties: {'from': 'LoginScreen'},
                              );
                              context.go('/register');
                            },
                            child: Text(
                              isMobile
                                  ? 'REGISTER'
                                  : 'REQUEST_CLEARANCE (REGISTER)',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                color: AppColors.white,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 10),
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
                            child: Text(
                              'FORGOT_PASSWORD?',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                color: AppColors.slate,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 10),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/'),
                            child: Text(
                              isMobile ? 'HOME' : 'ABORT_MISSION (HOME)',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                color: AppColors.slate,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          // null disables autofill on web/Android; also stop inline suggestions
          // so password managers cannot prefill saved credentials.
          autofillHints: isPassword ? null : const <String>[],
          enableSuggestions: !isPassword,
          autocorrect: !isPassword,
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
