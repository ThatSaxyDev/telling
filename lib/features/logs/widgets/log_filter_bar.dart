import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/log_level/log_level.dart';
import '../../../core/providers/filter_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/repositories/logs_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/searchable_user_dropdown.dart';

class LogFilterBar extends ConsumerStatefulWidget {
  const LogFilterBar({super.key});

  @override
  ConsumerState<LogFilterBar> createState() => _LogFilterBarState();
}

class _LogFilterBarState extends ConsumerState<LogFilterBar> {
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _selectedUserId = ref.read(logsProvider.notifier).userId;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ref.read(logsRepositoryProvider).fetchUsers();
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      // Silently fail - users filter is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppColors.slate.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            onChanged: notifier.setSearchQuery,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'SEARCH LOGS...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate),
              prefixIcon: const Icon(Icons.search, color: AppColors.slate),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.slate.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.slate.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdown<LogLevel>(
                  value: filter.level,
                  hint: 'ALL LEVELS',
                  items: [
                    const LogLevel.debug(),
                    const LogLevel.info(),
                    const LogLevel.warning(),
                    const LogLevel.error(),
                    const LogLevel.fatal(),
                  ],
                  onChanged: notifier.setLevel,
                  itemLabel: (level) => level.toString().split('.').last.toUpperCase(),
                ),
                const SizedBox(width: 16),
                _buildDropdown<LogType>(
                  value: filter.type,
                  hint: 'ALL TYPES',
                  items: [
                    const LogType.log(),
                    const LogType.errorr(),
                    const LogType.analytics(),
                    const LogType.event(),
                    const LogType.performance(),
                    const LogType.network(),
                  ],
                  onChanged: notifier.setType,
                  itemLabel: (type) => type.when(
                    log: () => 'LOG',
                    errorr: () => 'ERROR',
                    analytics: () => 'ANALYTICS',
                    event: () => 'EVENT',
                    performance: () => 'PERFORMANCE',
                    network: () => 'NETWORK',
                    custom: (name) => name.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 16),
                // User Filter
                SearchableUserDropdown(
                  selectedUserId: _selectedUserId,
                  users: _users,
                  onChanged: (userId) {
                    setState(() {
                      _selectedUserId = userId;
                    });
                    ref.read(logsProvider.notifier).setUserFilter(userId);
                  },
                ),
                const SizedBox(width: 16),
                if (filter.level != null || filter.type != null || (filter.searchQuery.isNotEmpty))
                  TextButton.icon(
                    onPressed: notifier.clearFilters,
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.error),
                    label: Text(
                      'CLEAR FILTERS',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border.all(color: AppColors.slate.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
          ),
          dropdownColor: AppColors.surfaceDark,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                hint,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
