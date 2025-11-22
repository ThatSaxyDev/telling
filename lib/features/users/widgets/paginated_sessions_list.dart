import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/users_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../logs/widgets/session_timeline_dialog.dart';

class PaginatedSessionsList extends ConsumerStatefulWidget {
  final String userId;

  const PaginatedSessionsList({super.key, required this.userId});

  @override
  ConsumerState<PaginatedSessionsList> createState() => _PaginatedSessionsListState();
}

class _PaginatedSessionsListState extends ConsumerState<PaginatedSessionsList> {
  final ScrollController _scrollController = ScrollController();
  
  List<UserSession> _sessions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  final int _limit = 20;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialSessions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSessions() async {
    setState(() {
      _isLoading = true;
      _currentOffset = 0;
    });
    
    try {
      final repository = ref.read(usersRepositoryProvider);
      final sessions = await repository.getUserSessions(
        widget.userId,
        limit: _limit,
        offset: _currentOffset,
      );
      
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _hasMore = sessions.length == _limit;
          _isLoading = false;
          _currentOffset = sessions.length;
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

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final repository = ref.read(usersRepositoryProvider);
      final newSessions = await repository.getUserSessions(
        widget.userId,
        limit: _limit,
        offset: _currentOffset,
      );
      
      if (mounted) {
        setState(() {
          _sessions.addAll(newSessions);
          _hasMore = newSessions.length == _limit;
          _isLoadingMore = false;
          _currentOffset += newSessions.length;
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
      _loadMoreSessions();
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

    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'No sessions recorded',
          style: TextStyle(color: AppColors.slate),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _sessions.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _sessions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return _SessionCard(session: _sessions[index]);
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final UserSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, HH:mm:ss');
    final duration = Duration(seconds: session.durationSeconds);
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SessionTimelineDialog(
            sessionId: session.sessionId,
            userName: null, // We are already in user details
            eventCount: session.eventCount,
            duration: duration,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(left: BorderSide(color: AppColors.secondary, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(session.startTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${duration.inMinutes}m ${duration.inSeconds % 60}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${session.eventCount} events logged',
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${session.sessionId}',
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
