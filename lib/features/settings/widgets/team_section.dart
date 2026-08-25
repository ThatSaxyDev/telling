import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/organization.dart';
import '../../../core/providers/organization_provider.dart';
import '../../../core/providers/project_provider.dart';
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
              'UNIT',
              style: (isMobile ? AppTextStyles.titleSmall : AppTextStyles.titleMedium)
                  .copyWith(color: AppColors.secondary),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // Active unit identity
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
            if (org.isOwner) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.slate, size: 18),
                tooltip: 'RENAME UNIT',
                onPressed: () => _confirmRename(org),
              ),
            ],
          ],
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Unit switcher + add-unit actions
        _buildUnitSwitcher(orgState, isMobile),
        SizedBox(height: isMobile ? 16 : 24),

        if (org.isOwner) ...[
          // Invite code
          _buildInviteCode(org, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          // Members
          _buildMembers(orgState, isMobile, sectionPadding),
        ] else
          // Operator (non-commander) actions
          _buildLeaveButton(),
      ],
    );
  }

  Widget _roleBadge(String role) {
    final isOwner = role == 'owner';
    final label = isOwner ? 'COMMANDER' : 'OPERATOR';
    final color = isOwner ? AppColors.secondary : AppColors.slate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(128)),
        color: color.withAlpha(26),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          letterSpacing: 1,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Lists all units (tap to switch active) plus create/join actions.
  Widget _buildUnitSwitcher(OrganizationState orgState, bool isMobile) {
    final activeOrg = orgState.organization;
    final units = orgState.units;

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
            'YOUR UNITS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.slate,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...units.map(
            (unit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: unit.id == activeOrg?.id
                    ? null
                    : () => _switchTo(unit.id),
                borderRadius: BorderRadius.zero,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: unit.id == activeOrg?.id
                          ? AppColors.secondary.withAlpha(128)
                          : AppColors.slate.withAlpha(51),
                    ),
                    color: unit.id == activeOrg?.id
                        ? AppColors.secondary.withAlpha(26)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.name.toUpperCase(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (unit.id == activeOrg?.id)
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: AppColors.secondary,
                        )
                      else
                        const Icon(
                          Icons.swap_horiz,
                          size: 14,
                          color: AppColors.slate,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (orgState.canCreateUnit)
                TextButton.icon(
                  onPressed: _showCreateUnitDialog,
                  icon: const Icon(Icons.add_moderator,
                      size: 16, color: AppColors.secondary),
                  label: const Text(
                    'CREATE NEW UNIT',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontFamily: 'Urbanist',
                      fontSize: 12,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: _showJoinUnitDialog,
                icon: const Icon(Icons.key,
                    size: 16, color: AppColors.slate),
                label: const Text(
                  'JOIN WITH CODE',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'You can command up to '
            '${OrganizationState.maxOwnedUnits} units. Joining others is unlimited.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.slate,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchTo(String organizationId) async {
    final switched =
        await ref.read(organizationProvider.notifier).switchUnit(organizationId);
    if (!switched) return;
    // Projects are scoped per unit — drop the stale selection and reload.
    final projects = ref.read(projectProvider.notifier);
    projects.reset();
    await projects.loadProjects();
  }

  void _showCreateUnitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.secondary),
        ),
        title: const Text(
          'CREATE NEW UNIT',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: AppColors.secondary,
          style: const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
          decoration: const InputDecoration(
            labelText: 'UNIT NAME (OPTIONAL)',
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
              'CANCEL',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ref
                  .read(organizationProvider.notifier)
                  .createOrganization(name: controller.text.trim());
              if (navigator.mounted) navigator.pop();
            },
            child: const Text(
              'CREATE',
              style: TextStyle(
                color: AppColors.secondary,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinUnitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.slate.withAlpha(77)),
        ),
        title: const Text(
          'JOIN UNIT',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: AppColors.secondary,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: 'Urbanist',
            letterSpacing: 2,
          ),
          decoration: const InputDecoration(
            labelText: 'INVITE CODE',
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
              'CANCEL',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              final navigator = Navigator.of(context);
              await ref
                  .read(organizationProvider.notifier)
                  .joinOrganization(code);
              if (navigator.mounted) navigator.pop();
            },
            child: const Text(
              'JOIN',
              style: TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
            ),
          ),
        ],
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
          const SizedBox(height: 8),
          Text(
            _expiryLabel(org.inviteCodeExpiresAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.slate,
              fontSize: 10,
            ),
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
                        Icons.swap_horiz,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                      tooltip: 'TRANSFER COMMAND',
                      onPressed: () => _confirmTransfer(member),
                    ),
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
          'Remove ${member.name} from the unit? They will lose access to all unit projects.',
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

  String _expiryLabel(DateTime? expiresAt) {
    if (expiresAt == null) return 'NO EXPIRY';
    final local = expiresAt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'EXPIRES ${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  void _confirmRename(Organization org) {
    final controller = TextEditingController(text: org.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.slate.withAlpha(77)),
        ),
        title: const Text(
          'RENAME UNIT',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: AppColors.secondary,
          style: const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
          decoration: const InputDecoration(
            labelText: 'UNIT NAME',
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
              'CANCEL',
              style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              ref.read(organizationProvider.notifier).rename(name);
              Navigator.pop(context);
            },
            child: const Text(
              'RENAME',
              style: TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmTransfer(OrganizationMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.secondary),
        ),
        title: const Text(
          'TRANSFER COMMAND',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.secondary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Transfer command of this unit to ${member.name}? You will become an operator.',
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
              ref
                  .read(organizationProvider.notifier)
                  .transferOwnership(member.id);
              Navigator.pop(context);
            },
            child: const Text(
              'TRANSFER',
              style: TextStyle(
                color: AppColors.secondary,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error),
        ),
        title: const Text(
          'LEAVE UNIT',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.error,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Leave this unit? You will lose access to all its projects.',
          style: TextStyle(
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
              ref.read(organizationProvider.notifier).leave();
              Navigator.pop(context);
            },
            child: const Text(
              'LEAVE',
              style: TextStyle(color: AppColors.error, fontFamily: 'Urbanist'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _confirmLeave,
        icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
        label: const Text(
          'LEAVE UNIT',
          style: TextStyle(
            color: AppColors.error,
            fontFamily: 'Urbanist',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
