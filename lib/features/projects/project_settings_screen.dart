import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';

class ProjectSettingsScreen extends ConsumerWidget {
  const ProjectSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);
    final project = projectState.selectedProject;

    if (project == null) {
      return const Center(
        child: Text(
          'NO_PROJECT_SELECTED',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.slate,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROJECT_CONFIGURATION',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          MilitaryHoverContainer(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROJECT_DETAILS',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.slate,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('NAME', project.name),
                  const SizedBox(height: 16),
                  _buildDetailRow('ID', project.id),
                  const SizedBox(height: 16),
                  _buildDetailRow('CREATED', project.createdAt.toString().split(' ')[0]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          MilitaryHoverContainer(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCESS_CREDENTIALS',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.slate,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'API_KEY',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.slate,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            border: Border.all(color: AppColors.slate.withAlpha(77)),
                          ),
                          child: Text(
                            project.apiKey,
                            style: const TextStyle(
                              fontFamily: 'Urbanist',
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: project.apiKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('API_KEY_COPIED_TO_CLIPBOARD'),
                              backgroundColor: AppColors.surfaceDark,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, color: AppColors.slate),
                        tooltip: 'COPY_KEY',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WARNING: REGENERATING_KEY_WILL_INVALIDATE_OLD_KEY',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.error,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Version Config Button
          MilitaryHoverContainer(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/projects/version-config'),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(26),
                          border: Border.all(
                            color: AppColors.secondary.withAlpha(77),
                          ),
                        ),
                        child: const Icon(
                          Icons.system_update,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERSION_CONFIG',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure force update settings for your app',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                color: AppColors.slate.withAlpha(179),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.slate),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.slate,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
