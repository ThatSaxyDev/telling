import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/organization_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';

class OrganizationOnboardingScreen extends ConsumerStatefulWidget {
  const OrganizationOnboardingScreen({super.key});

  @override
  ConsumerState<OrganizationOnboardingScreen> createState() =>
      _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState
    extends ConsumerState<OrganizationOnboardingScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(color: Color(0xFF222222), spacing: 40),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ESTABLISH YOUR UNIT',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Every operator belongs to a unit. Create your own '
                        'or join an existing one with an invite code.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (orgState.isLoading)
                        const MilitaryLoader(label: 'PROCESSING...')
                      else ...[
                        // Unit name (optional — server defaults to a generated name)
                        TextField(
                          controller: _nameController,
                          cursorColor: AppColors.secondary,
                          textCapitalization: TextCapitalization.words,
                          maxLength: 50,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontFamily: 'Urbanist',
                            letterSpacing: 1,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'UNIT NAME (OPTIONAL)',
                            labelStyle: TextStyle(
                              color: AppColors.slate,
                              fontFamily: 'Urbanist',
                            ),
                            hintText: 'E.G. ALPHA SQUAD',
                            hintStyle: TextStyle(
                              color: AppColors.slate,
                              fontFamily: 'Urbanist',
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.slate),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Create team
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'CREATE MY UNIT',
                            icon: Icons.add_moderator,
                            onPressed: () async {
                              final ok = await ref
                                  .read(organizationProvider.notifier)
                                  .createOrganization(
                                    name: _nameController.text.trim(),
                                  );
                              if (ok && context.mounted) {
                                context.go('/projects');
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.slate),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.slate,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.slate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _codeController,
                          cursorColor: AppColors.secondary,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontFamily: 'Urbanist',
                            letterSpacing: 2,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'INVITE CODE',
                            labelStyle: TextStyle(
                              color: AppColors.slate,
                              fontFamily: 'Urbanist',
                            ),
                            hintText: 'ABCD2345',
                            hintStyle: TextStyle(
                              color: AppColors.slate,
                              fontFamily: 'Urbanist',
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.slate),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'JOIN WITH CODE',
                            icon: Icons.keyboard_alt_outlined,
                            isOutlined: true,
                            onPressed: () async {
                              final code = _codeController.text.trim();
                              if (code.isEmpty) return;
                              final ok = await ref
                                  .read(organizationProvider.notifier)
                                  .joinOrganization(code);
                              if (ok && context.mounted) {
                                context.go('/projects');
                              }
                            },
                          ),
                        ),

                        if (orgState.error != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.error),
                              color: AppColors.error.withAlpha(26),
                            ),
                            child: Text(
                              orgState.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: Scanline(color: Color(0x0DFFFFFF))),
          ),
        ],
      ),
    );
  }
}
