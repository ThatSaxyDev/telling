import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling/core/models/project.dart';
import 'package:telling/core/providers/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import '../../shared/widgets/app_button.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/constants/funnel_constants.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    // Step 1: Projects Screen Viewed (Project Creation Funnel)
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.projectCreationFunnel,
      stepName: FunnelConstants.projectsScreenViewed,
      step: 1,
    );
    
    // Step 7: Projects Screen Viewed (Onboarding Funnel)
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.onboardingFunnel,
      stepName: FunnelConstants.projectsViewed,
      step: 7,
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Grid
          const Positioned.fill(
            child: GridBackground(color: Color(0xFF222222), spacing: 40),
          ),

          // Content
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 600;
              final isTablet = width >= 600 && width < 900;

              // Responsive values
              final double contentMaxWidth = isMobile
                  ? width
                  : (isTablet ? 700 : 1000);
              final double horizontalPadding = isMobile ? 16 : 24;
              final double verticalPadding = isMobile ? 16 : 24;
              final double gridMaxCrossAxisExtent = isMobile
                  ? 400
                  : 300; // Full width on mobile
              final double childAspectRatio = isMobile ? 1.4 : 1.2;

              return SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: [
                                const Icon(
                                  Icons.grid_view,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TypingText(
                                    text: isMobile
                                        ? 'PROJECTS'
                                        : 'PROJECT SELECTION',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.white,
                                      letterSpacing: 2,
                                      fontSize: isMobile ? 20 : 24,
                                    ),
                                    duration: const Duration(milliseconds: 50),
                                  ),
                                ),
                                if (!isMobile) const Spacer(),
                                if (isMobile) const SizedBox(width: 12),
                                AppButton(
                                  text: isMobile ? '' : 'LOGOUT',
                                  icon: Icons.logout,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  onPressed: () {
                                    ref.read(authProvider.notifier).logout();
                                    ref.read(projectProvider.notifier).reset();
                                    context.go('/login');
                                  },
                                  backgroundColor: AppColors.error.withAlpha(
                                    26,
                                  ),
                                  borderColor: AppColors.error,
                                  foregroundColor: AppColors.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: AppColors.primary.withAlpha(128),
                            ),
                            const SizedBox(height: 32),

                            // Error Message
                            if (projectState.error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.error),
                                  color: AppColors.error.withAlpha(26),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        projectState.error!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Projects Grid
                            if (projectState.isLoading &&
                                projectState.projects.isEmpty)
                              const Center(
                                child: MilitaryLoader(
                                  label: 'LOADING PROJECTS...',
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent:
                                          gridMaxCrossAxisExtent,
                                      childAspectRatio: childAspectRatio,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: projectState.projects.length + 1,
                                itemBuilder: (context, index) {
                                  // Add New Project Card
                                  if (index == projectState.projects.length) {
                                    final isLimitReached =
                                        projectState.projects.length >= 3;
                                    return _buildAddProjectCard(
                                      context,
                                      ref,
                                      isLimitReached,
                                    );
                                  }

                                  final project = projectState.projects[index];
                                  return _buildProjectCard(
                                    context,
                                    ref,
                                    project,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Scanline Overlay
          const Positioned.fill(
            child: IgnorePointer(child: Scanline(color: Color(0x0DFFFFFF))),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.primary.withAlpha(26),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceDark,
              AppColors.surfaceDark.withAlpha(200),
              AppColors.primary.withAlpha(10),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    border: Border.all(color: AppColors.primary.withAlpha(77)),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name.toUpperCase(),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${project.id.substring(0, 8)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.slate,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.slate,
                  ),
                  onPressed: () => _confirmDelete(context, ref, project),
                  tooltip: 'DELETE PROJECT',
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'ENTER SYSTEM',
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: () {
                  // Step 8: Project Selected (Onboarding Funnel)
                  Telling.instance.trackFunnel(
                    funnelName: FunnelConstants.onboardingFunnel,
                    stepName: FunnelConstants.projectSelected,
                    step: 8,
                    properties: {'project_name': project.name},
                  );
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

  Widget _buildAddProjectCard(
    BuildContext context,
    WidgetRef ref,
    bool isLimitReached,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLimitReached ? null : () => _showCreateDialog(context, ref),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isLimitReached
                  ? AppColors.slate.withAlpha(51)
                  : AppColors.slate.withAlpha(128),
              style: BorderStyle.solid,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLimitReached
                  ? [
                      AppColors.backgroundDark.withAlpha(128),
                      AppColors.backgroundDark.withAlpha(128),
                    ]
                  : [
                      AppColors.surfaceDark.withAlpha(77),
                      AppColors.surfaceDark.withAlpha(26),
                    ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: isLimitReached
                    ? AppColors.slate.withAlpha(77)
                    : AppColors.slate,
              ),
              const SizedBox(height: 12),
              Text(
                isLimitReached ? 'LIMIT REACHED (3/3)' : 'INITIATE NEW PROJECT',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isLimitReached
                      ? AppColors.slate.withAlpha(77)
                      : AppColors.slate,
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
    // Step 2: Create Project Clicked
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.projectCreationFunnel,
      stepName: FunnelConstants.createProjectClicked,
      step: 2,
    );

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.slate.withAlpha(77)),
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
          cursorColor: AppColors.secondary,
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: 'Urbanist',
          ),
          decoration: const InputDecoration(
            labelText: 'PROJECT CODENAME',
            labelStyle: TextStyle(
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
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // Step 3: Create Project Submitted
                Telling.instance.trackFunnel(
                  funnelName: FunnelConstants.projectCreationFunnel,
                  stepName: FunnelConstants.createProjectSubmitted,
                  step: 3,
                  properties: {'project_name': controller.text},
                );

                await ref
                    .read(projectProvider.notifier)
                    .createProject(controller.text);
                
                if (context.mounted) {
                  final error = ref.read(projectProvider).error;
                  if (error == null) {
                    // Step 4: Project Created Successfully
                    Telling.instance.trackFunnel(
                      funnelName: FunnelConstants.projectCreationFunnel,
                      stepName: FunnelConstants.projectCreated,
                      step: 4,
                      properties: {'project_name': controller.text},
                    );
                  }
                  Navigator.pop(context);
                }
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
        shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.error)),
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
