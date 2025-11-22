import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/log_entry.dart';
import '../../../core/providers/users_provider.dart';
import '../../../core/theme/app_colors.dart';

class PaginatedLogsList extends ConsumerStatefulWidget {
  final String userId;

  const PaginatedLogsList({super.key, required this.userId});

  @override
  ConsumerState<PaginatedLogsList> createState() => _PaginatedLogsListState();
}

class _PaginatedLogsListState extends ConsumerState<PaginatedLogsList> {
  final ScrollController _scrollController = ScrollController();
  
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  final int _limit = 30;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLogs() async {
    setState(() {
      _isLoading = true;
      _currentOffset = 0;
    });
    
    try {
      final repository = ref.read(usersRepositoryProvider);
      final logs = await repository.getUserLogs(
        widget.userId,
        limit: _limit,
        offset: _currentOffset,
      );
      
      if (mounted) {
        setState(() {
          _logs = logs;
          _hasMore = logs.length == _limit;
          _isLoading = false;
          _currentOffset = logs.length;
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
      final repository = ref.read(usersRepositoryProvider);
      final newLogs = await repository.getUserLogs(
        widget.userId,
        limit: _limit,
        offset: _currentOffset,
      );
      
      if (mounted) {
        setState(() {
          _logs.addAll(newLogs);
          _hasMore = newLogs.length == _limit;
          _isLoadingMore = false;
          _currentOffset += newLogs.length;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'No logs recorded',
          style: TextStyle(color: AppColors.slate),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _logs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _logs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return _LogItem(log: _logs[index]);
      },
    );
  }
}

class _LogItem extends StatelessWidget {
  final LogEntry log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm:ss.SSS');
    
    Color levelColor;
    switch (log.level.toLowerCase()) {
      case 'fatal':
        levelColor = Colors.red.shade900;
        break;
      case 'error':
        levelColor = AppColors.error;
        break;
      case 'warning':
        levelColor = Colors.orange;
        break;
      case 'info':
        levelColor = AppColors.white;
        break;
      case 'debug':
        levelColor = AppColors.primary;
        break;
      default:
        levelColor = AppColors.slate;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(left: BorderSide(color: levelColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  log.level.toUpperCase(),
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                dateFormat.format(log.timestamp),
                style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.message,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
            ),
          ),
          if (log.stackTrace != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.stackTrace!,
                style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
