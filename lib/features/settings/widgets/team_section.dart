import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/organization.dart';
import '../../../core/providers/organization_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TeamSection extends ConsumerStatefulWidget {
  const TeamSection({super.key});

  @override
  ConsumerState<TeamSection> createState() => _TeamSectionState();
}

class _TeamSectionState extends ConsumerState<TeamSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(organizationProvider);
      if (state.isOwner && state.members.isEmpty && !state.membersLoading) {
        ref.read(organizationProvider.notifier).loadMembers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationProvider);
    final org = orgState.organization;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final sectionPadding = isMobile ? 16.0 : 24.0;

    if (org == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.groups,
              color: AppColors.secondary,
              size: isMobile ? 20 : 24,
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Text(
              'TEAM',
              style: (isMobile ? AppTextStyles.titleSmall : AppTextStyles.titleMedium)
                  .copyWith(color: AppColors.secondary),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // Team identity
        Row(
          children: [
            Expanded(
              child: Text(
                org.name.toUpperCase(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            _roleBadge(org.role),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 24),

        if (org.isOwner) ...[
          // Invite code
          _buildInviteCode(org, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          // Members
          _buildMembers(orgState, isMobile, sectionPadding),
        ],
      ],
    );
  }

  Widget _roleBadge(String role) {
    final isOwner = role == 'owner';
    final color = isOwner ? AppColors.secondary : AppColors.slate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(128)),
        color: color.withAlpha(26),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          letterSpacing: 1,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInviteCode(Organization org, bool isMobile) {
    final code = org.inviteCode ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.slate.withAlpha(77)),
        color: AppColors.backgroundDark.withAlpha(128),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVITE CODE',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.slate,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.white,
                    letterSpacing: 4,
                    fontFamily: 'SourceCodePro',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.slate, size: 20),
                tooltip: 'COPY CODE',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'INVITE CODE COPIED',
                        style: TextStyle(fontFamily: 'Urbanist'),
                      ),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.slate, size: 20),
                tooltip: 'REGENERATE CODE',
                onPressed: () async {
                  await ref.read(organizationProvider.notifier).regenerateCode();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembers(
    OrganizationState orgState,
    bool isMobile,
    double sectionPadding,
  ) {
    final members = orgState.members;
    final isLoading = orgState.membersLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEMBERS',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.slate,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading && members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'LOADING MEMBERS...',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          )
        else if (members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'NO MEMBERS FOUND',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          )
        else
          ...members.map(
            (member) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.slate.withAlpha(51)),
                color: AppColors.surfaceDark.withAlpha(128),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name.toUpperCase(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          member.email,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.slate,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _roleBadge(member.role),
                  if (member.role != 'owner') ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.person_remove_outlined,
                        color: AppColors.error,
                        size: 18,
                      ),
                      tooltip: 'REMOVE MEMBER',
                      onPressed: () =>
                          _confirmRemoveMember(member),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _confirmRemoveMember(OrganizationMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error),
        ),
        title: const Text(
          'REMOVE MEMBER',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.error,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Remove ${member.name} from the team? They will lose access to all team projects.',
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
              ref.read(organizationProvider.notifier).removeMember(member.id);
              Navigator.pop(context);
            },
            child: const Text(
              'REMOVE',
              style: TextStyle(color: AppColors.error, fontFamily: 'Urbanist'),
            ),
          ),
        ],
      ),
    );
  }
}
