import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/models/log_level/log_level.dart';
import '../../../core/models/log_model/log_model.dart';
import '../../../core/providers/activity_timeline_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/military_decorations.dart';
import '../../../shared/widgets/military_loader.dart';
import '../../../shared/painters/corner_bracket_painter.dart';

class ActivityTimeline extends ConsumerStatefulWidget {
  const ActivityTimeline({super.key});

  @override
  ConsumerState<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<ActivityTimeline> {
  LogLevel? _filterLevel;
  LogType? _filterType;
  final ScrollController _scrollController = ScrollController();

  List<LogModel> _logs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Try to load from provider cache first, then fetch if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cachedData = ref.read(activityTimelineProvider);
      cachedData.whenData((logs) {
        if (mounted && logs.isNotEmpty) {
          setState(() {
            _logs = logs;
            _hasMore = logs.length == 20;
            _isLoading = false;
          });
        } else if (mounted) {
          _loadInitialLogs();
        }
      });

      // If no cache or error, load normally
      if (!cachedData.hasValue || cachedData.value!.isEmpty) {
        _loadInitialLogs();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLogs() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final authState = ref.read(authProvider);
      final projectState = ref.read(projectProvider);

      if (authState.user == null || projectState.selectedProject == null) {
        if (mounted) {
          setState(() {
            _logs = [];
            _isLoading = false;
          });
        }
        return;
      }

      final repository = ref.read(logsRepositoryProvider);
      final logs = await repository.fetchLogs(
        page: _currentPage,
        limit: 20,
        projectId: projectState.selectedProject!.id,
      );

      if (mounted) {
        setState(() {
          _logs = logs;
          _hasMore = logs.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final authState = ref.read(authProvider);
      final projectState = ref.read(projectProvider);

      if (authState.user == null || projectState.selectedProject == null) {
        setState(() => _isLoadingMore = false);
        return;
      }

      final repository = ref.read(logsRepositoryProvider);
      _currentPage++;
      final newLogs = await repository.fetchLogs(
        page: _currentPage,
        limit: 20,
        projectId: projectState.selectedProject!.id,
      );

      if (mounted) {
        setState(() {
          _logs.addAll(newLogs);
          _hasMore = newLogs.length == 20;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreLogs();
    }
  }

  List<LogModel> _filterLogs(List<LogModel> logs) {
    return logs.where((log) {
      // Level filter
      if (_filterLevel != null && log.level != _filterLevel) {
        return false;
      }

      // Type filter
      if (_filterType != null && log.type != _filterType) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.slate.withAlpha(128),
      showGrid: false,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Column(
          children: [
            // Compact Filter Bar
            _buildCompactFilterBar(),
            const SizedBox(height: 16),

            // Timeline Content
            Expanded(
              child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: MilitaryLoader(label: 'LOADING ACTIVITY...', size: 60),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error loading activity: $_error',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      );
    }

    final filteredLogs = _filterLogs(_logs);

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline, size: 48, color: AppColors.slate),
            const SizedBox(height: 16),
            Text(
              _logs.isEmpty ? 'NO ACTIVITY DETECTED' : 'NO MATCHING ACTIVITY',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: filteredLogs.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == filteredLogs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: MilitaryLoader(label: 'LOADING MORE...', size: 30),
            ),
          );
        }

        final log = filteredLogs[index];
        return _buildTimelineItem(
          log,
          index == filteredLogs.length - 1 && !_hasMore,
        );
      },
    );
  }

  Widget _buildCompactFilterBar() {
    return Row(
      children: [
        // Level filter
        _buildCompactDropdown<LogLevel>(
          value: _filterLevel,
          hint: 'ALL LEVELS',
          items: const [
            LogLevel.trace(),
            LogLevel.debug(),
            LogLevel.info(),
            LogLevel.warning(),
            LogLevel.error(),
            LogLevel.fatal(),
          ],
          onChanged: (level) => setState(() => _filterLevel = level),
          itemLabel: (level) => level.toString().split('.').last.toUpperCase(),
        ),

        const SizedBox(width: 12),

        // Type filter
        _buildCompactDropdown<LogType>(
          value: _filterType,
          hint: 'TYPE',
          items: const [
            LogType.general(),
            LogType.analytics(),
            LogType.event(),
            LogType.performance(),
            LogType.network(),
            LogType.security(),
            LogType.exception(),
            LogType.crash(),
          ],
          onChanged: (type) => setState(() => _filterType = type),
          itemLabel: (type) => type.when(
            general: () => 'GENERAL',
            analytics: () => 'ANALYTICS',
            event: () => 'EVENT',
            performance: () => 'PERFORMANCE',
            network: () => 'NETWORK',
            security: () => 'SECURITY',
            exception: () => 'EXCEPTION',
            crash: () => 'CRASH',
            custom: (name) => name.toUpperCase(),
          ),
        ),

        // Clear filters
        if (_filterLevel != null || _filterType != null) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _filterLevel = null;
                _filterType = null;
              });
            },
            icon: const Icon(Icons.clear, size: 18, color: AppColors.error),
            tooltip: 'Clear Filters',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.slate),
          ),
          isDense: true,
          dropdownColor: AppColors.surfaceDark,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.secondary,
            size: 18,
          ),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                hint,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                ),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(LogModel log, bool isLast) {
    final color = _getLevelColor(log.level);
    final typeColor = _getTypeColor(log.type);
    final timeStr = _formatTime(log.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tactical dot with hex design
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hexagon-style outer
                    Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: color.withAlpha(128),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // Inner dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(179),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Connecting line
                if (!isLast)
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withAlpha(128),
                          AppColors.slate.withAlpha(26),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Main content with tactical frame
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    color.withAlpha(3),
                    AppColors.backgroundDark.withAlpha(77),
                    AppColors.backgroundDark.withAlpha(38),
                  ],
                ),
                border: Border(
                  left: BorderSide(color: color, width: 3),
                  top: BorderSide(color: color.withAlpha(77), width: 1),
                  right: BorderSide(
                    color: AppColors.slate.withAlpha(51),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: AppColors.slate.withAlpha(51),
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact header
                        Row(
                          children: [
                            // Level indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(38),
                                border: Border.all(color: color, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getLevelIcon(log.level),
                                    size: 11,
                                    color: color,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    log.level
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Type badge (if not default)
                            if (log.type != const LogType.general())
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withAlpha(26),
                                  border: Border.all(
                                    color: typeColor.withAlpha(128),
                                  ),
                                ),
                                child: Text(
                                  _getTypeLabel(log.type),
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Timestamp
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: AppColors.slate,
                                fontSize: 10,
                                fontFamily: 'Urbanist',
                                letterSpacing: 0.5,
                              ),
                            ),

                            // User indicator
                            if (log.userName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.secondary.withAlpha(128),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 9,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      log.userName!,
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Message
                        Text(
                          log.message,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            height: 1.3,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Top-left corner bracket
                  Positioned(
                    top: 0,
                    left: 0,
                    child: CustomPaint(
                      size: const Size(8, 8),
                      painter: CornerBracketPainter(
                        color: color,
                        isTopLeft: true,
                      ),
                    ),
                  ),

                  // Bottom-right corner bracket
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CustomPaint(
                      size: const Size(8, 8),
                      painter: CornerBracketPainter(
                        color: color.withAlpha(77),
                        isTopLeft: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLevelIcon(LogLevel level) {
    return level.when(
      trace: () => Icons.bug_report,
      debug: () => Icons.bug_report,
      info: () => Icons.info_outline,
      warning: () => Icons.warning_amber,
      error: () => Icons.error_outline,
      fatal: () => Icons.dangerous,
    );
  }

  Color _getTypeColor(LogType type) {
    return type.when(
      general: () => AppColors.slate,
      analytics: () => Colors.purple,
      event: () => Colors.green,
      performance: () => Colors.amber,
      network: () => Colors.blue,
      security: () => Colors.red,
      exception: () => Colors.orange,
      crash: () => Colors.red.shade900,
      custom: (name) => AppColors.primary,
    );
  }

  String _getTypeLabel(LogType type) {
    return type.when(
      general: () => 'GEN',
      analytics: () => 'ANA',
      event: () => 'EVT',
      performance: () => 'PRF',
      network: () => 'NET',
      security: () => 'SEC',
      exception: () => 'EXC',
      crash: () => 'CRS',
      custom: (name) => name.substring(0, 3).toUpperCase(),
    );
  }

  Color _getLevelColor(LogLevel level) {
    return level.when(
      trace: () => AppColors.slate.withAlpha(179),
      debug: () => AppColors.slate,
      info: () => Colors.blue,
      warning: () => Colors.orange,
      error: () => AppColors.error,
      fatal: () => Colors.red,
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
