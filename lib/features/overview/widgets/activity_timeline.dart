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
import '../../../core/extensions/responsive_extension.dart';
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
    final isMobile = context.isMobile;
    
    return MilitaryHoverContainer(
      baseColor: AppColors.surfaceDark,
      hoverColor: AppColors.slate.withAlpha(128),
      showGrid: !isMobile,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Column(
          children: [
            // Compact Filter Bar
            _buildCompactFilterBar(isMobile),
            SizedBox(height: isMobile ? 10 : 16),

            // Timeline Content
            Expanded(
              child: _buildContent(isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return Center(
        child: MilitaryLoader(
          label: isMobile ? 'LOADING...' : 'LOADING ACTIVITY...',
          size: isMobile ? 40 : 60,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error loading activity: $_error',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    final filteredLogs = _filterLogs(_logs);

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: isMobile ? 36 : 48, color: AppColors.slate),
            SizedBox(height: isMobile ? 8 : 16),
            Text(
              _logs.isEmpty ? 'NO ACTIVITY' : 'NO MATCHES',
              style: (isMobile ? AppTextStyles.labelLarge : AppTextStyles.titleMedium).copyWith(
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: filteredLogs.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => SizedBox(height: isMobile ? 6 : 8),
      itemBuilder: (context, index) {
        if (index == filteredLogs.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 16.0),
              child: MilitaryLoader(
                label: 'LOADING...',
                size: isMobile ? 24 : 30,
              ),
            ),
          );
        }

        final log = filteredLogs[index];
        return _buildTimelineItem(
          log,
          index == filteredLogs.length - 1 && !_hasMore,
          isMobile,
        );
      },
    );
  }

  Widget _buildCompactFilterBar(bool isMobile) {
    return Row(
      children: [
        // Level filter
        Expanded(
          child: _buildCompactDropdown<LogLevel>(
            value: _filterLevel,
            hint: isMobile ? 'LEVEL' : 'ALL LEVELS',
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
            isMobile: isMobile,
          ),
        ),

        SizedBox(width: isMobile ? 8 : 12),

        // Type filter
        Expanded(
          child: _buildCompactDropdown<LogType>(
            value: _filterType,
            hint: 'TYPE',
            items: const [
              LogType.general(),
              LogType.analytics(),
              LogType.crash(),
              LogType.performance(),
            ],
            onChanged: (type) => setState(() => _filterType = type),
            itemLabel: (type) => type.when(
              general: () => 'GENERAL',
              analytics: () => 'ANALYTICS',
              crash: () => 'CRASH',
              performance: () => 'PERFORMANCE',
            ),
            isMobile: isMobile,
          ),
        ),

        // Clear filters
        if (_filterLevel != null || _filterType != null) ...[
          SizedBox(width: isMobile ? 6 : 12),
          IconButton(
            onPressed: () {
              setState(() {
                _filterLevel = null;
                _filterType = null;
              });
            },
            icon: Icon(Icons.clear, size: isMobile ? 16 : 18, color: AppColors.error),
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
    bool isMobile = false,
  }) {
    return Container(
      height: isMobile ? 32 : 36,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10),
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
          isDense: true,
          isExpanded: true,
          dropdownColor: AppColors.surfaceDark,
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.secondary,
            size: isMobile ? 16 : 18,
          ),
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
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontSize: isMobile ? 10 : 12,
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

  Widget _buildTimelineItem(LogModel log, bool isLast, bool isMobile) {
    final color = _getLevelColor(log.level);
    final typeColor = _getTypeColor(log.type);
    final timeStr = _formatTime(log.timestamp);

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tactical dot with hex design
          SizedBox(
            width: isMobile ? 16 : 20,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hexagon-style outer
                    Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: Container(
                        width: isMobile ? 8 : 10,
                        height: isMobile ? 8 : 10,
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
                      width: isMobile ? 4 : 6,
                      height: isMobile ? 4 : 6,
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(179),
                            blurRadius: isMobile ? 4 : 6,
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
                    height: isMobile ? 40 : 52,
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

          SizedBox(width: isMobile ? 8 : 12),

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
                  left: BorderSide(color: color, width: isMobile ? 2 : 3),
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
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 8 : 12,
                      isMobile ? 8 : 10,
                      isMobile ? 8 : 12,
                      isMobile ? 8 : 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact header - stack on mobile if needed
                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Level indicator
                                      _buildLevelBadge(log, color, isMobile),
                                      const SizedBox(width: 6),
                                      // Type badge
                                      if (log.type != const LogType.general())
                                        _buildTypeBadge(log, typeColor, isMobile),
                                      const Spacer(),
                                      // Timestamp
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: AppColors.slate,
                                          fontSize: 9,
                                          fontFamily: 'Urbanist',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // Level indicator
                                  _buildLevelBadge(log, color, isMobile),
                                  const SizedBox(width: 8),
                                  // Type badge
                                  if (log.type != const LogType.general())
                                    _buildTypeBadge(log, typeColor, isMobile),
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
                                    _buildUserBadge(log, isMobile),
                                  ],
                                ],
                              ),

                        SizedBox(height: isMobile ? 4 : 6),

                        // Message
                        Text(
                          log.message,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: isMobile ? 11 : 13,
                            height: 1.3,
                            letterSpacing: 0.2,
                          ),
                          maxLines: isMobile ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Corner brackets - hide on mobile for cleaner look
                  if (!isMobile) ...[
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(LogModel log, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 6,
        vertical: isMobile ? 1 : 2,
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
            size: isMobile ? 9 : 11,
            color: color,
          ),
          SizedBox(width: isMobile ? 2 : 3),
          Text(
            log.level.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 8 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: isMobile ? 0.5 : 1,
              fontFamily: 'Urbanist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(LogModel log, Color typeColor, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 5,
        vertical: isMobile ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: typeColor.withAlpha(26),
        border: Border.all(color: typeColor.withAlpha(128)),
      ),
      child: Text(
        _getTypeLabel(log.type),
        style: TextStyle(
          color: typeColor,
          fontSize: isMobile ? 7 : 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserBadge(LogModel log, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 3 : 4,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondary.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: isMobile ? 8 : 9,
            color: AppColors.secondary,
          ),
          SizedBox(width: isMobile ? 1 : 2),
          Text(
            log.userName!,
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w600,
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
      crash: () => Colors.red.shade900,
      performance: () => Colors.amber,
    );
  }

  String _getTypeLabel(LogType type) {
    return type.when(
      general: () => 'GEN',
      analytics: () => 'ANA',
      crash: () => 'CRS',
      performance: () => 'PRF',
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
