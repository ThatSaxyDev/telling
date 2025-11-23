import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProjectSelector extends ConsumerWidget {
  const ProjectSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);
    final selectedProject = projectState.selectedProject;
    final isLimitReached = projectState.projects.length >= 3;

    return PopupMenuButton<String>(
      tooltip: 'SELECT_PROJECT',
      offset: const Offset(0, 40),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.slate.withOpacity(0.3)),
      ),
      itemBuilder: (context) {
        return [
          ...projectState.projects.map(
            (project) => PopupMenuItem(
              value: project.id,
              child: Text(
                project.name.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: isLimitReached ? null : 'new_project',
            enabled: !isLimitReached,
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: 14,
                  color: isLimitReached ? AppColors.slate.withOpacity(0.3) : AppColors.slate,
                ),
                const SizedBox(width: 8),
                Text(
                  isLimitReached ? 'LIMIT REACHED (3/3)' : 'NEW_PROJECT',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: isLimitReached ? AppColors.slate.withOpacity(0.3) : AppColors.slate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 'new_project') {
          _showCreateProjectDialog(context, ref);
        } else {
          final project = projectState.projects.firstWhere((p) => p.id == value);
          ref.read(projectProvider.notifier).selectProject(project);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withOpacity(0.3)),
          color: AppColors.backgroundDark,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 14, color: AppColors.slate),
            const SizedBox(width: 8),
            Text(
              selectedProject?.name.toUpperCase() ?? 'SELECT_PROJECT',
              style: const TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.slate),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.slate.withOpacity(0.3)),
        ),
        title: const Text(
          'INITIATE_NEW_PROJECT',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: AppColors.secondary,
          style: const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
          decoration: const InputDecoration(
            labelText: 'PROJECT_CODENAME',
            labelStyle: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.slate),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.white),
            ),
          ),
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
}
