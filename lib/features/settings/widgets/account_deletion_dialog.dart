import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/military_decorations.dart';

class AccountDeletionDialog extends StatefulWidget {
  const AccountDeletionDialog({super.key});

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    setState(() {
      _isValid = value.trim().toLowerCase() == 'delete';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: MilitaryHoverContainer(
        baseColor: AppColors.error,
        showGrid: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            border: Border.all(color: AppColors.error),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DANGER ZONE',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Are you absolutely sure?',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. This will permanently delete your account and remove all associated data from our servers. Any units you command will also be deleted, and their members will lose access.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Type "delete" to confirm',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                onChanged: _validateInput,
                cursorColor: AppColors.error,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'delete',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate.withAlpha(100),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Check if we have enough width for the row layout
                  // Assuming roughly 150px for delete button and 80px for cancel + spacing
                  final isTight = constraints.maxWidth < 300;
                  
                  if (isTight) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton(
                          text: 'DELETE ACCOUNT',
                          icon: Icons.delete_forever,
                          onPressed: _isValid
                              ? () => Navigator.of(context).pop(true)
                              : () {},
                          backgroundColor: _isValid
                              ? AppColors.error.withAlpha(26)
                              : AppColors.slate.withAlpha(26),
                          borderColor:
                              _isValid ? AppColors.error : AppColors.slate,
                          foregroundColor:
                              _isValid ? AppColors.error : AppColors.slate,
                          height: 40,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'CANCEL',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'CANCEL',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AppButton(
                        text: 'DELETE ACCOUNT',
                        icon: Icons.delete_forever,
                        onPressed: _isValid
                            ? () => Navigator.of(context).pop(true)
                            : () {},
                        backgroundColor: _isValid
                            ? AppColors.error.withAlpha(26)
                            : AppColors.slate.withAlpha(26),
                        borderColor: _isValid ? AppColors.error : AppColors.slate,
                        foregroundColor:
                            _isValid ? AppColors.error : AppColors.slate,
                        height: 40,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
