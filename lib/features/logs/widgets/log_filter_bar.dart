import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/log_level/log_level.dart';
import '../../../core/models/filter_state/filter_state.dart';
import '../../../core/providers/filter_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/extensions/responsive_extension.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/searchable_user_dropdown.dart';

class LogFilterBar extends ConsumerStatefulWidget {
  const LogFilterBar({super.key});

  @override
  ConsumerState<LogFilterBar> createState() => _LogFilterBarState();
}

class _LogFilterBarState extends ConsumerState<LogFilterBar>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;
  bool _filtersExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _selectedUserId = ref.read(logsProvider.notifier).userId;
    _loadUsers();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _filtersExpanded = !_filtersExpanded;
      if (_filtersExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _loadUsers() async {
    try {
      final projectState = ref.read(projectProvider);
      if (projectState.selectedProject == null) return;

      final users = await ref
          .read(logsRepositoryProvider)
          .fetchUsers(projectId: projectState.selectedProject!.id);
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
    final isMobile = context.isMobile;
    
    // Check if any filters are active (for badge indicator)
    final hasActiveFilters = filter.level != null || 
        filter.type != null || 
        _selectedUserId != null;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            onChanged: notifier.setSearchQuery,
            cursorColor: AppColors.secondary,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'SEARCH LOGS...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate),
              prefixIcon: const Icon(Icons.search, color: AppColors.slate),
              // Filter toggle icon on mobile
              suffixIcon: isMobile
                  ? GestureDetector(
                      onTap: _toggleFilters,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Stack(
                          children: [
                            AnimatedRotation(
                              turns: _filtersExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _filtersExpanded ? Icons.close : Icons.tune,
                                color:  AppColors.slate,
                                size: 22,
                              ),
                            ),
                            // Active filter indicator badge
                            if (hasActiveFilters && !_filtersExpanded)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.backgroundDark,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 12 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          
          // Filters Row - always visible on desktop, animated on mobile
          if (isMobile)
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1,
              child: _buildFiltersContent(filter, notifier, isMobile),
            )
          else
            _buildFiltersContent(filter, notifier, isMobile),
        ],
      ),
    );
  }

  Widget _buildFiltersContent(FilterState filter, FilterNotifier notifier, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isMobile ? 12 : 16),
        
        // Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDropdown<LogLevel>(
                value: filter.level,
                hint: 'ALL LEVELS',
                items: [
                  const LogLevel.trace(),
                  const LogLevel.debug(),
                  const LogLevel.info(),
                  const LogLevel.warning(),
                  const LogLevel.error(),
                  const LogLevel.fatal(),
                ],
                onChanged: notifier.setLevel,
                itemLabel: (level) => level.toString().split('.').last.toUpperCase(),
                isMobile: isMobile,
              ),
              SizedBox(width: isMobile ? 8 : 16),
              _buildDropdown<LogType>(
                value: filter.type,
                hint: 'ALL TYPES',
                items: [
                  const LogType.general(),
                  const LogType.analytics(),
                  const LogType.crash(),
                  const LogType.performance(),
                ],
                onChanged: notifier.setType,
                itemLabel: (type) => type.when(
                  general: () => 'GENERAL',
                  analytics: () => 'ANALYTICS',
                  crash: () => 'CRASH',
                  performance: () => 'PERFORMANCE',
                ),
                isMobile: isMobile,
              ),
              SizedBox(width: isMobile ? 8 : 64),
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
              SizedBox(width: isMobile ? 8 : 16),
              if (filter.level != null || filter.type != null || filter.searchQuery.isNotEmpty || _selectedUserId != null)
                TextButton.icon(
                  onPressed: () {
                    notifier.clearFilters();
                    setState(() {
                      _selectedUserId = null;
                    });
                    ref.read(logsProvider.notifier).setUserFilter(null);
                  },
                  icon: Icon(Icons.clear, size: isMobile ? 14 : 16, color: AppColors.error),
                  label: Text(
                    isMobile ? 'CLEAR' : 'CLEAR FILTERS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemLabel,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border.all(color: AppColors.slate.withAlpha(77)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.slate,
              fontSize: isMobile ? 10 : 12,
            ),
          ),
          dropdownColor: AppColors.surfaceDark,
          icon: Icon(
            Icons.arrow_drop_down, 
            color: AppColors.secondary,
            size: isMobile ? 18 : 24,
          ),
          isDense: isMobile,
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                hint,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
