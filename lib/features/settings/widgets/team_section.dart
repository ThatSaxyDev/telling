import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/organization.dart';
import '../../../core/providers/organization_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/unit_dialogs.dart';

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
      if (state.members.isEmpty && !state.membersLoading) {
        ref.read(organizationProvider.notifier).loadMembers();
      }
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Urbanist'),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
      ),
    );
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
        // Role explainer
        const SizedBox(height: 4),
        Text(
          org.isOwner
              ? 'COMMANDERS MANAGE PROJECTS, MEMBERS AND INVITES'
              : 'OPERATORS HAVE VIEW-ONLY ACCESS TO UNIT PROJECTS',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.slate,
            fontSize: 10,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Unit switcher + add-unit actions
        _buildUnitSwitcher(orgState, isMobile),
        SizedBox(height: isMobile ? 16 : 24),

        if (org.isOwner) ...[
          // Invite code (commander only)
          _buildInviteCode(org, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
        ],
        // Members — visible to every unit member; actions are commander-only
        _buildMembers(orgState, isMobile, sectionPadding),
        SizedBox(height: isMobile ? 16 : 24),

        if (!org.isOwner)
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
            '${orgState.maxOwnedUnits} units. Joining others is unlimited.',
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

  void _showCreateUnitDialog() => showCreateUnitDialog(context, ref);

  void _showJoinUnitDialog() => showJoinUnitDialog(context, ref);

  Widget _buildInviteCode(Organization org, bool isMobile) {
    final code = org.inviteCode ?? '—';
    final expiresAt = org.inviteCodeExpiresAt;
    final expiringSoon = expiresAt != null &&
        expiresAt.isBefore(DateTime.now().add(const Duration(days: 7)));

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
                onPressed: () => _confirmRegenerate(org),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_expiryLabel(org.inviteCodeExpiresAt)}'
            '${expiringSoon ? ' — EXPIRING SOON' : ''}',
            style: AppTextStyles.labelSmall.copyWith(
              color: expiringSoon ? AppColors.error : AppColors.slate,
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
          'MEMBERS (${members.length})',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.slate,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (!orgState.isOwner)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'READ-ONLY — COMMANDERS MANAGE MEMBERS',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.slate,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
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
                        if (member.email != null)
                          Text(
                            member.email!,
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
                  if (orgState.isOwner && member.role != 'owner') ...[
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
    bool busy = false;
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove ${member.name} from the unit? They will lose access to all unit projects.',
                style: const TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  height: 1.5,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      final success = await ref
                          .read(organizationProvider.notifier)
                          .removeMember(member.id);
                      if (!mounted || !dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext);
                        _showSnack('MEMBER REMOVED');
                      } else {
                        setDialogState(() => error = 'Could not remove member');
                      }
                    },
              child: Text(
                busy ? 'REMOVING...' : 'REMOVE',
                style:
                    const TextStyle(color: AppColors.error, fontFamily: 'Urbanist'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRegenerate(Organization org) {
    final controller = TextEditingController();
    bool busy = false;
    String? validationError;
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.secondary),
          ),
          title: const Text(
            'REGENERATE INVITE CODE',
            style: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The current code stops working immediately. Leave the field '
                'empty for a code that never expires.',
                style: TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  height: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                cursorColor: AppColors.secondary,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppColors.white,
                  fontFamily: 'Urbanist',
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'VALID FOR DAYS (EMPTY = NO EXPIRY)',
                  labelStyle: const TextStyle(
                    color: AppColors.slate,
                    fontFamily: 'Urbanist',
                    fontSize: 11,
                  ),
                  errorText: validationError,
                  errorStyle: const TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Urbanist',
                    fontSize: 11,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.slate),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      final days = text.isEmpty ? null : int.tryParse(text);
                      if (text.isNotEmpty &&
                          (days == null || days < 1 || days > 365)) {
                        setDialogState(() => validationError =
                            'ENTER A NUMBER BETWEEN 1 AND 365');
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      final newCode = await ref
                          .read(organizationProvider.notifier)
                          .regenerateCode(expiryDays: days);
                      if (!mounted || !dialogContext.mounted) return;
                      if (newCode != null) {
                        Navigator.pop(dialogContext);
                        _showSnack('INVITE CODE ROTATED');
                      } else {
                        setDialogState(() => error = 'Could not rotate code');
                      }
                    },
              child: Text(
                busy ? 'ROTATING...' : 'ROTATE',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
          ],
        ),
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
    bool busy = false;
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                cursorColor: AppColors.secondary,
                style:
                    const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'UNIT NAME',
                  labelStyle:
                      TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.slate),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      final success = await ref
                          .read(organizationProvider.notifier)
                          .rename(name);
                      if (!mounted || !dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext);
                        _showSnack('UNIT RENAMED');
                      } else {
                        setDialogState(() => error = 'Could not rename unit');
                      }
                    },
              child: Text(
                busy ? 'RENAMING...' : 'RENAME',
                style:
                    const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTransfer(OrganizationMember member) {
    bool busy = false;
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer command of this unit to ${member.name}? You will become an operator.',
                style: const TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  height: 1.5,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      final success = await ref
                          .read(organizationProvider.notifier)
                          .transferOwnership(member.id);
                      if (!mounted || !dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext);
                        _showSnack('COMMAND TRANSFERRED');
                      } else {
                        setDialogState(
                            () => error = 'Could not transfer command');
                      }
                    },
              child: Text(
                busy ? 'TRANSFERRING...' : 'TRANSFER',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave() {
    bool busy = false;
    String? error;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leave this unit? You will lose access to all its projects.',
                style: TextStyle(
                  color: AppColors.slate,
                  fontFamily: 'Urbanist',
                  height: 1.5,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Urbanist',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.slate, fontFamily: 'Urbanist'),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      final success = await ref
                          .read(organizationProvider.notifier)
                          .leave();
                      if (!mounted || !dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext);
                        _showSnack('LEFT UNIT');
                      } else {
                        setDialogState(() => error = 'Could not leave unit');
                      }
                    },
              child: Text(
                busy ? 'LEAVING...' : 'LEAVE',
                style:
                    const TextStyle(color: AppColors.error, fontFamily: 'Urbanist'),
              ),
            ),
          ],
        ),
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
