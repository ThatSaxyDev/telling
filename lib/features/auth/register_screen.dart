import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/funnel_constants.dart';
import '../../shared/widgets/military_decorations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Step 3: Register Screen Viewed (Onboarding Funnel)
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.onboardingFunnel,
      stepName: FunnelConstants.registerViewed,
      step: 3,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PASSWORDS_DO_NOT_MATCH'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Step 4: Register Submitted (Onboarding Funnel)
      Telling.instance.trackFunnel(
        funnelName: FunnelConstants.onboardingFunnel,
        stepName: FunnelConstants.registerSubmitted,
        step: 4,
        properties: {'method': 'email'},
      );

      final result = await ref
          .read(authProvider.notifier)
          .register(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
      
      if (result != null && mounted) {
        context.go(
          '/verify-otp',
          extra: {'userId': result['userId'], 'email': _emailController.text},
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
                          isMobile ? 'REGISTER' : 'NEW_OPERATOR // REGISTRATION',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            color: AppColors.white,
                            fontSize: isMobile ? 18 : 20,
                            letterSpacing: isMobile ? 1 : 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 32),
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
                          controller: _nameController,
                          label: 'OPERATOR_NAME',
                          icon: Icons.badge_outlined,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'OPERATOR_ID (EMAIL)',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'REQUIRED_FIELD';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'INVALID_EMAIL_FORMAT';
                            }
                            return null;
                          },
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
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'CONFIRM_ACCESS_CODE',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onTogglePasswordVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'REQUIRED_FIELD';
                            }
                            if (value != _passwordController.text) {
                              return 'PASSWORDS_DO_NOT_MATCH';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 20 : 32),
                        SizedBox(
                          width: double.infinity,
                          height: isMobile ? 44 : 48,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _register,
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
                                : Text(
                                    isMobile ? 'REGISTER' : 'SUBMIT_CREDENTIALS',
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      fontSize: isMobile ? 13 : 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              isMobile ? 'BACK TO LOGIN' : 'RETURN_TO_LOGIN',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
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
    String? Function(String?)? validator,
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
          cursorColor: AppColors.secondary,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
          ),
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
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'REQUIRED_FIELD';
                }
                return null;
              },
        ),
      ],
    );
  }
}
