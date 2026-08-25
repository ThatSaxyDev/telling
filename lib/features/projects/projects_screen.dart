import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling/core/models/project.dart';
import 'package:telling/core/providers/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/organization_provider.dart';
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
    final orgState = ref.watch(organizationProvider);
    final isOwner = orgState.isOwner;
    final orgName = orgState.organization?.name;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
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
        
                // Build the main content
                final contentWidget = Container(
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
                              text: isMobile ? 'PROJECTS' : 'PROJECT SELECTION',
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                              ref.read(projectProvider.notifier).reset();
                              context.go('/login');
                            },
                            backgroundColor: AppColors.error.withAlpha(26),
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

                      // Team banner
                      if (orgName != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.slate.withAlpha(77),
                            ),
                            color: AppColors.surfaceDark.withAlpha(128),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: AppColors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${orgName.toUpperCase()}  —  ${isOwner ? 'OWNER' : 'MEMBER'}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.slate,
                                    letterSpacing: 1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

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
        
                      // Projects Grid/List
                      if (projectState.isLoading &&
                          projectState.projects.isEmpty)
                        const Center(
                          child: MilitaryLoader(label: 'LOADING PROJECTS...'),
                        )
                      else if (isMobile)
                        // Mobile: Use single column ListView
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              projectState.projects.length + (isOwner ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == projectState.projects.length) {
                              final isLimitReached =
                                  projectState.projects.length >= 3;
                              return _buildAddProjectCard(
                                context,
                                ref,
                                isLimitReached,
                                isMobile: true,
                              );
                            }
                            final project = projectState.projects[index];
                            return _buildProjectCard(
                              context,
                              ref,
                              project,
                              isMobile: true,
                            );
                          },
                        )
                      else
                        // Tablet/Desktop: Use Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: gridMaxCrossAxisExtent,
                                childAspectRatio: childAspectRatio,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount:
                              projectState.projects.length + (isOwner ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == projectState.projects.length) {
                              final isLimitReached =
                                  projectState.projects.length >= 3;
                              return _buildAddProjectCard(
                                context,
                                ref,
                                isLimitReached,
                                isMobile: false,
                              );
                            }
                            final project = projectState.projects[index];
                            return _buildProjectCard(
                              context,
                              ref,
                              project,
                              isMobile: false,
                            );
                          },
                        ),
                    ],
                  ),
                );

                // Mobile: No vertical centering (content at top)
                // Desktop/Tablet: Vertical centering
                return SafeArea(
                  child: SingleChildScrollView(
                    child: isMobile
                        ? Center(child: contentWidget)
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(child: contentWidget),
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
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    WidgetRef ref,
    Project project, {
    bool isMobile = false,
  }) {
    final isOwner = ref.read(organizationProvider).isOwner;
    final content = Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: isMobile
          ? // Mobile: Horizontal layout
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate.withAlpha(26),
                    border: Border.all(color: AppColors.slate.withAlpha(77)),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: AppColors.slate,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 2),
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
                const SizedBox(width: 8),
                AppButton(
                  text: 'OPEN',
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () {
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
                if (isOwner)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.slate,
                    ),
                    onPressed: () => _confirmDelete(context, ref, project),
                    tooltip: 'DELETE PROJECT',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            )
          : // Desktop/Tablet: Vertical layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.slate.withAlpha(26),
                        border: Border.all(
                          color: AppColors.slate.withAlpha(77),
                        ),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: AppColors.slate,
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
                    if (isOwner)
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
    );

    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.primary.withAlpha(26),
      child: content,
    );
  }

  Widget _buildAddProjectCard(
    BuildContext context,
    WidgetRef ref,
    bool isLimitReached, {
    bool isMobile = false,
  }) {
    final content = Container(
      padding: isMobile ? const EdgeInsets.symmetric(vertical: 20) : null,
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
      child: isMobile
          ? // Mobile: Horizontal layout
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 24,
                  color: isLimitReached
                      ? AppColors.slate.withAlpha(77)
                      : AppColors.slate,
                ),
                const SizedBox(width: 12),
                Text(
                  isLimitReached
                      ? 'LIMIT REACHED (3/3)'
                      : 'INITIATE NEW PROJECT',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isLimitReached
                        ? AppColors.slate.withAlpha(77)
                        : AppColors.slate,
                    letterSpacing: 1,
                  ),
                ),
              ],
            )
          : // Desktop/Tablet: Vertical layout
            Column(
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
                  isLimitReached
                      ? 'LIMIT REACHED (3/3)'
                      : 'INITIATE NEW PROJECT',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isLimitReached
                        ? AppColors.slate.withAlpha(77)
                        : AppColors.slate,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLimitReached ? null : () => _showCreateDialog(context, ref),
        child: content,
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
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                cursorColor: AppColors.secondary,
                enabled: !isLoading,
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
                  disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.slate),
                  ),
                ),
                autofocus: true,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'CREATING PROJECT...',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontFamily: 'Urbanist',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'ABORT',
                style: TextStyle(
                  color: isLoading
                      ? AppColors.slate.withAlpha(77)
                      : AppColors.slate,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (controller.text.isNotEmpty) {
                        setState(() => isLoading = true);

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
              child: Text(
                'EXECUTE',
                style: TextStyle(
                  color: isLoading
                      ? AppColors.white.withAlpha(77)
                      : AppColors.white,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
          ],
        ),
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
