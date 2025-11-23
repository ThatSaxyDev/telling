import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String _obscureKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
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
                      border: Border.all(
                        color: AppColors.slate.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _isVisible
                          ? project.apiKey
                          : _obscureKey(project.apiKey),
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.white,
                        fontSize: 12,
                        letterSpacing: _isVisible ? 0 : 2,
                      ),
                    ),
                  ),
                  Row(
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
                        backgroundColor: AppColors.slate.withOpacity(0.1),
                        borderColor: AppColors.slate,
                        foregroundColor: AppColors.slate,
                      ),
                      const SizedBox(width: 12),
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
                              backgroundColor: AppColors.surfaceDark,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        backgroundColor: AppColors.secondary.withOpacity(0.1),
                        borderColor: AppColors.secondary,
                        foregroundColor: AppColors.secondary,
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
                      border: Border.all(
                        color: AppColors.slate.withOpacity(0.3),
                      ),
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
                  backgroundColor: AppColors.slate.withOpacity(0.1),
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
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  borderColor: AppColors.secondary,
                  foregroundColor: AppColors.secondary,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
