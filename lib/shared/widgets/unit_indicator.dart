import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/organization_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'unit_dialogs.dart';

/// Compact active-unit chip shown in the app shell so the current unit
/// context stays visible on every screen. Tap to switch between units.
class UnitIndicator extends ConsumerStatefulWidget {
  const UnitIndicator({super.key});

  @override
  ConsumerState<UnitIndicator> createState() => _UnitIndicatorState();
}

class _UnitIndicatorState extends ConsumerState<UnitIndicator> {
  Future<void> _switchTo(String unitId) async {
    final switched =
        await ref.read(organizationProvider.notifier).switchUnit(unitId);
    if (!switched) return;
    // Projects are scoped per unit — drop the stale selection and reload.
    // With no project selected the router sends the user to /projects.
    final projects = ref.read(projectProvider.notifier);
    projects.reset();
    await projects.loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationProvider);
    final org = orgState.organization;
    if (org == null || !orgState.isLoaded) return const SizedBox.shrink();

    final hasMultipleUnits = orgState.units.length > 1;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.slate.withAlpha(77)),
        color: AppColors.surfaceDark.withAlpha(128),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${org.name.toUpperCase()} · ${org.isOwner ? 'CMDR' : 'OPR'}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.slate,
                letterSpacing: 1,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMultipleUnits) ...[
            const SizedBox(width: 6),
            const Icon(Icons.swap_vert, color: AppColors.slate, size: 12),
          ],
        ],
      ),
    );

    if (!hasMultipleUnits) return chip;

    return PopupMenuButton<String>(
      tooltip: 'SWITCH_UNIT',
      offset: const Offset(0, 36),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.slate.withAlpha(77)),
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      itemBuilder: (context) => [
        for (final unit in orgState.units)
          PopupMenuItem(
            value: unit.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    unit.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 12,
                      fontWeight: unit.id == org.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  unit.isOwner ? 'CMDR' : 'OPR',
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 10,
                    color: AppColors.slate,
                  ),
                ),
                if (unit.id == org.id) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 14, color: AppColors.secondary),
                ],
              ],
            ),
          ),
        ...unitMenuActionEntries(
          canCreate: orgState.canCreateUnit,
          ownedCount: orgState.ownedCount,
        ),
      ],
      onSelected: (value) {
        if (value == unitMenuCreate) {
          showCreateUnitDialog(context, ref);
        } else if (value == unitMenuJoin) {
          showJoinUnitDialog(context, ref);
        } else {
          _switchTo(value);
        }
      },
      child: chip,
    );
  }
}
