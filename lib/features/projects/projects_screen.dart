import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import '../../shared/widgets/app_button.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Grid
          const Positioned.fill(
            child: GridBackground(
              color: Color(0xFF222222),
              spacing: 40,
            ),
          ),

          // Content
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.grid_view, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'PROJECT SELECTION',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      // Logout button could go here
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 32),

                  // Error Message
                  if (projectState.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.error),
                        color: AppColors.error.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(
                            projectState.error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),

                  // Projects Grid
                  if (projectState.isLoading && projectState.projects.isEmpty)
                    const Center(child: MilitaryLoader(label: 'LOADING PROJECTS...'))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: projectState.projects.length + 1,
                      itemBuilder: (context, index) {
                        // Add New Project Card
                        if (index == projectState.projects.length) {
                          final isLimitReached = projectState.projects.length >= 3;
                          return _buildAddProjectCard(context, ref, isLimitReached);
                        }

                        final project = projectState.projects[index];
                        return _buildProjectCard(context, ref, project);
                      },
                    ),
                ],
              ),
            ),
          ),

          // Scanline Overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: Scanline(color: Color(0x0DFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, WidgetRef ref, dynamic project) {
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.primary.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withOpacity(0.3)),
          color: AppColors.surfaceDark,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.name.toUpperCase(),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.slate),
                  onPressed: () => _confirmDelete(context, ref, project),
                  tooltip: 'DELETE PROJECT',
                ),
              ],
            ),
            const Spacer(),
            Text(
              'ID: ${project.id.substring(0, 8)}...',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'ENTER SYSTEM',
                onPressed: () {
                  ref.read(projectProvider.notifier).selectProject(project);
                  context.go('/');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProjectCard(BuildContext context, WidgetRef ref, bool isLimitReached) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLimitReached ? null : () => _showCreateDialog(context, ref),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isLimitReached 
                  ? AppColors.slate.withOpacity(0.2) 
                  : AppColors.slate.withOpacity(0.5),
              style: BorderStyle.solid,
            ),
            color: isLimitReached 
                ? AppColors.backgroundDark.withOpacity(0.5) 
                : AppColors.surfaceDark.withOpacity(0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: isLimitReached ? AppColors.slate.withOpacity(0.3) : AppColors.slate,
              ),
              const SizedBox(height: 12),
              Text(
                isLimitReached ? 'LIMIT REACHED (3/3)' : 'INITIATE NEW PROJECT',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isLimitReached ? AppColors.slate.withOpacity(0.3) : AppColors.slate,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.slate.withOpacity(0.3)),
        ),
        title: const Text(
          'INITIATE NEW PROJECT',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
          decoration: const InputDecoration(
            labelText: 'PROJECT CODENAME',
            labelStyle: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.slate),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ABORT',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(projectProvider.notifier).createProject(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'EXECUTE',
              style: TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'CONFIRM DELETION',
              style: TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete project "${project.name}"?\n\nThis action is irreversible and will destroy all associated logs.',
          style: const TextStyle(
            color: AppColors.slate,
            fontFamily: 'Urbanist',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectProvider.notifier).deleteProject(project.id);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: AppColors.error, fontFamily: 'Urbanist'),
            ),
          ),
        ],
      ),
    );
  }
}
