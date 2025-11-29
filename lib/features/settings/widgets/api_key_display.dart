import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class ApiKeyDisplay extends ConsumerStatefulWidget {
  const ApiKeyDisplay({super.key});

  @override
  ConsumerState<ApiKeyDisplay> createState() => _ApiKeyDisplayState();
}

class _ApiKeyDisplayState extends ConsumerState<ApiKeyDisplay> {
  bool _isVisible = false;
  bool _isRegenerating = false;

  String _obscureKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  Future<void> _regenerateApiKey() async {
    final project = ref.read(projectProvider).selectedProject;
    if (project == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDark,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border.all(color: AppColors.slate.withAlpha(77)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    'REGENERATE API KEY',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WARNING',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will IMMEDIATELY invalidate your current API key. All existing SDK integrations will stop working until updated with the new key.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'CANCEL',
                      onPressed: () => Navigator.of(context).pop(false),
                      backgroundColor: AppColors.slate.withAlpha(26),
                      borderColor: AppColors.slate,
                      foregroundColor: AppColors.slate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: 'REGENERATE',
                      icon: Icons.refresh,
                      onPressed: () => Navigator.of(context).pop(true),
                      backgroundColor: Colors.orange.withAlpha(26),
                      borderColor: Colors.orange,
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRegenerating = true;
    });

    final newKey = await ref
        .read(projectProvider.notifier)
        .regenerateApiKey(project.id);

    setState(() {
      _isRegenerating = false;
    });

    if (newKey != null && mounted) {
      Telling.instance.event(
        'Action: API Key Regenerated',
        properties: {'projectId': project.id},
      );

      // Auto-copy new key to clipboard
      await Clipboard.setData(ClipboardData(text: newKey));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'NEW API KEY GENERATED AND COPIED TO CLIPBOARD',
              style: TextStyle(fontFamily: 'Urbanist'),
            ),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Show the new key
      setState(() {
        _isVisible = true;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'FAILED TO REGENERATE API KEY',
            style: TextStyle(fontFamily: 'Urbanist'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final project = projectState.selectedProject;

    if (project == null) {
      return Text(
        'NO PROJECT SELECTED',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROJECT: ${project.name.toUpperCase()}',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 1100;
            if (isSmallScreen) {
              return Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      border: Border.all(color: AppColors.slate.withAlpha(77)),
                    ),
                    child: Text(
                      _isVisible ? project.apiKey : _obscureKey(project.apiKey),
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.white,
                        fontSize: 12,
                        letterSpacing: _isVisible ? 0 : 2,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AppButton(
                        text: _isVisible ? 'HIDE' : 'REVEAL',
                        icon: _isVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        onPressed: () {
                          setState(() {
                            _isVisible = !_isVisible;
                          });
                        },
                        backgroundColor: AppColors.slate.withAlpha(26),
                        borderColor: AppColors.slate,
                        foregroundColor: AppColors.slate,
                      ),
                      AppButton(
                        text: 'COPY',
                        icon: Icons.copy,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: project.apiKey),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'API KEY COPIED TO CLIPBOARD',
                                style: TextStyle(fontFamily: 'Urbanist'),
                              ),
                              backgroundColor: AppColors.white,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        backgroundColor: AppColors.secondary.withAlpha(26),
                        borderColor: AppColors.secondary,
                        foregroundColor: AppColors.secondary,
                      ),
                      AppButton(
                        text: _isRegenerating
                            ? 'REGENERATING...'
                            : 'REGENERATE',
                        icon: _isRegenerating ? null : Icons.refresh,
                        onPressed: _isRegenerating ? null : _regenerateApiKey,
                        backgroundColor: Colors.orange.withAlpha(26),
                        borderColor: Colors.orange,
                        foregroundColor: Colors.orange,
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      border: Border.all(color: AppColors.slate.withAlpha(77)),
                    ),
                    child: Text(
                      _isVisible ? project.apiKey : _obscureKey(project.apiKey),
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.white,
                        fontSize: 12,
                        letterSpacing: _isVisible ? 0 : 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: _isVisible ? 'HIDE' : 'REVEAL',
                  icon: _isVisible ? Icons.visibility_off : Icons.visibility,
                  onPressed: () {
                    setState(() {
                      _isVisible = !_isVisible;
                    });
                  },
                  backgroundColor: AppColors.slate.withAlpha(26),
                  borderColor: AppColors.slate,
                  foregroundColor: AppColors.slate,
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: 'COPY',
                  icon: Icons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: project.apiKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'API KEY COPIED TO CLIPBOARD',
                          style: TextStyle(fontFamily: 'Urbanist'),
                        ),
                        backgroundColor: AppColors.secondary,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  backgroundColor: AppColors.secondary.withAlpha(26),
                  borderColor: AppColors.secondary,
                  foregroundColor: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: _isRegenerating ? 'REGENERATING...' : 'REGENERATE',
                  icon: _isRegenerating ? null : Icons.refresh,
                  onPressed: _isRegenerating ? null : _regenerateApiKey,
                  backgroundColor: Colors.orange.withAlpha(26),
                  borderColor: Colors.orange,
                  foregroundColor: Colors.orange,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
