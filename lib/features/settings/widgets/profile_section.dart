import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:telling/shared/widgets/military_loader.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/military_decorations.dart';

class ProfileSection extends ConsumerWidget {
  const ProfileSection({super.key});

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      showGrid: false,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'PROFILE',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.slate.withAlpha(77)),
                    color: AppColors.slate.withAlpha(26),
                  ),
                  child: Text(
                    'VIEW ONLY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            profileAsync.when(
              data: (profile) => Column(
                children: [
                  _buildInfoRow(
                    label: 'EMAIL',
                    value: profile.email,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  if (profile.name != null) ...[
                    _buildInfoRow(
                      label: 'NAME',
                      value: profile.name!,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildInfoRow(
                    label: 'USER ID',
                    value: profile.id,
                    icon: Icons.fingerprint,
                    isMonospace: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    label: 'ACCOUNT CREATED',
                    value: _formatDate(profile.createdAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: MilitaryLoader(),
                ),
              ),
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load profile',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.slate, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white,
                  fontFamily: isMonospace ? 'Courier' : 'Urbanist',
                  fontSize: isMonospace ? 11 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
