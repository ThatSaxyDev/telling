import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/organization_provider.dart';
import '../../core/theme/app_colors.dart';

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Urbanist')),
      backgroundColor: isError ? AppColors.error : AppColors.secondary,
    ),
  );
}

/// Dialog to create a new unit (optional name). Usable from any surface.
Future<void> showCreateUnitDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  bool busy = false;
  String? error;
  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.secondary)),
        title: const Text(
          'CREATE NEW UNIT',
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
              autofocus: true,
              style:
                  const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
              decoration: const InputDecoration(
                labelText: 'UNIT NAME (OPTIONAL)',
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
                        .createOrganization(name: controller.text.trim());
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(dialogContext);
                      _showSnack(context, 'UNIT CREATED');
                    } else {
                      setDialogState(() {
                        busy = false;
                        error = ref.read(organizationProvider).error ??
                            'Could not create unit';
                      });
                    }
                  },
            child: Text(
              busy ? 'CREATING...' : 'CREATE',
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

/// Dialog to join a unit via invite code. Usable from any surface.
Future<void> showJoinUnitDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  bool busy = false;
  String? error;
  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              cursorColor: AppColors.secondary,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: AppColors.white,
                fontFamily: 'Urbanist',
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                labelText: 'INVITE CODE',
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
                    final code = controller.text.trim();
                    if (code.isEmpty) return;
                    setDialogState(() {
                      busy = true;
                      error = null;
                    });
                    final success = await ref
                        .read(organizationProvider.notifier)
                        .joinOrganization(code);
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(dialogContext);
                      _showSnack(context, 'UNIT JOINED');
                    } else {
                      setDialogState(() {
                        busy = false;
                        error = ref.read(organizationProvider).error ??
                            'Could not join unit';
                      });
                    }
                  },
            child: Text(
              busy ? 'JOINING...' : 'JOIN',
              style:
                  const TextStyle(color: AppColors.white, fontFamily: 'Urbanist'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Reserved popup-menu values shared by unit switcher menus.
const unitMenuCreate = '__unit_create__';
const unitMenuJoin = '__unit_join__';

/// Menu entries appended to unit switcher popups (create/join actions).
List<PopupMenuEntry<String>> unitMenuActionEntries({
  required bool canCreate,
  required int ownedCount,
}) {
  return [
    const PopupMenuDivider(),
    if (canCreate)
      const PopupMenuItem(
        value: unitMenuCreate,
        height: 40,
        child: Row(
          children: [
            Icon(Icons.add_moderator, size: 14, color: AppColors.secondary),
            SizedBox(width: 8),
            Text(
              'CREATE_NEW_UNIT',
              style: TextStyle(fontFamily: 'Urbanist', color: AppColors.white, fontSize: 12),
            ),
          ],
        ),
      )
    else
      PopupMenuItem(
        value: null,
        enabled: false,
        height: 40,
        child: Row(
          children: [
            Icon(Icons.add_moderator,
                size: 14, color: AppColors.slate.withAlpha(77)),
            const SizedBox(width: 8),
            Text(
              'UNIT LIMIT REACHED ($ownedCount/2)',
              style: TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.slate.withAlpha(77),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    const PopupMenuItem(
      value: unitMenuJoin,
      height: 40,
      child: Row(
        children: [
          Icon(Icons.key, size: 14, color: AppColors.slate),
          SizedBox(width: 8),
          Text(
            'JOIN_WITH_CODE',
            style: TextStyle(fontFamily: 'Urbanist', color: AppColors.slate, fontSize: 12),
          ),
        ],
      ),
    ),
  ];
}
