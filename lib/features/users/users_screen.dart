import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:telling/core/theme/app_colors.dart';
import 'package:telling/core/theme/app_text_styles.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/providers/users_provider.dart';
import '../../core/models/user.dart';
import '../../core/utils/error_formatter.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import '../../shared/widgets/app_button.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      final userName = (user.userName ?? '').toLowerCase();
      final userId = user.userId.toLowerCase();
      final userEmail = (user.userEmail ?? '').toLowerCase();

      return userName.contains(query) ||
          userId.contains(query) ||
          userEmail.contains(query);
    }).toList();
  }

  List<User> _paginateUsers(List<User> users) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= users.length) {
      return [];
    }

    return users.sublist(
      startIndex,
      endIndex > users.length ? users.length : endIndex,
    );
  }

  int _getTotalPages(int totalUsers) {
    return (totalUsers / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isMobile ? 12.0 : 24.0;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 12.0 : 24.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border(
              bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_alt,
                          color: AppColors.slate,
                          size: isMobile ? 24 : 32,
                        ),
                        SizedBox(width: isMobile ? 8 : 16),
                        Flexible(
                          child: GlitchText(
                            text: 'USERS',
                            style: isMobile
                                ? AppTextStyles.titleSmall
                                : AppTextStyles.headlineSmall,
                            glitchAmount: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 16),
                  Row(
                    children: [
                      AppButton(
                        text: isMobile ? '' : 'REFRESH',
                        icon: Icons.refresh,
                        isOutlined: true,
                        onPressed: () {
                          ref.invalidate(usersListProvider);
                        },
                        width: isMobile ? 36 : null,
                        height: isMobile ? 36 : null,
                        padding: isMobile ? EdgeInsets.zero : null,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Search Bar
              TextField(
                controller: _searchController,
                cursorColor: AppColors.secondary,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'SEARCH USERS...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.slate),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.slate),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: AppColors.slate.withAlpha(77),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: AppColors.slate.withAlpha(77),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1; // Reset to first page on search
                  });
                },
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: usersAsync.when(
            loading: () =>
                const Center(child: MilitaryLoader(label: 'LOADING USERS...')),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ERROR LOADING USERS',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ErrorFormatter.format(err),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            data: (users) {
              final filteredUsers = _filterUsers(users);

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty
                            ? Icons.person_off_outlined
                            : Icons.search_off,
                        size: 48,
                        color: AppColors.slate,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'NO USER DATA DETECTED'
                            : 'NO USERS FOUND',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final paginatedUsers = _paginateUsers(filteredUsers);
              final totalPages = _getTotalPages(filteredUsers.length);

              return Column(
                children: [
                  // Results info
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ).copyWith(top: isMobile ? 8 : 10),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + paginatedUsers.length} of ${filteredUsers.length}',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),

                  // Users list
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 0,
                      ),
                      itemCount: paginatedUsers.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: isMobile ? 8 : 12),
                      itemBuilder: (context, index) {
                        final user = paginatedUsers[index];
                        return _buildUserItem(context, user, isMobile);
                      },
                    ),
                  ),

                  // Pagination controls
                  if (totalPages > 1) _buildPaginationControls(totalPages, isMobile),
                ],
              );
            },
          ),
        ),
      ],
    ).nowTelling(name: 'User Screen Reached');
  }

  Widget _buildPaginationControls(int totalPages, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.white.withAlpha(26), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          if (isMobile)
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: _currentPage > 1 ? AppColors.white : AppColors.slate,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 1
                      ? AppColors.primary.withAlpha(51)
                      : AppColors.darkSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: 100,
              child: AppButton(
                text: 'PREVIOUS',
                onPressed: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                backgroundColor: _currentPage > 1
                    ? AppColors.white
                    : AppColors.darkSlate,
                foregroundColor: _currentPage > 1
                    ? AppColors.primary
                    : AppColors.slate,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

          SizedBox(width: isMobile ? 12 : 16),

          // Page Indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white.withAlpha(51)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isMobile ? '$_currentPage / $totalPages' : 'PAGE $_currentPage OF $totalPages',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: isMobile ? 1.0 : 1.5,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),

          SizedBox(width: isMobile ? 12 : 16),

          // Next Button
          if (isMobile)
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: _currentPage < totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: _currentPage < totalPages ? AppColors.white : AppColors.slate,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < totalPages
                      ? AppColors.primary.withAlpha(51)
                      : AppColors.darkSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: 100,
              child: AppButton(
                text: 'NEXT',
                onPressed: _currentPage < totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                backgroundColor: _currentPage < totalPages
                    ? AppColors.white
                    : AppColors.darkSlate,
                foregroundColor: _currentPage < totalPages
                    ? AppColors.primary
                    : AppColors.slate,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, User user, bool isMobile) {
    final dateFormat = DateFormat(isMobile ? 'MMM d, HH:mm' : 'MMM d, HH:mm:ss');

    return MilitaryHoverContainer(
      onTap: () {
        ref.invalidate(userStatsProvider(user.userId));
        context.go('/users/${user.userId}');
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            left: BorderSide(color: AppColors.secondary, width: isMobile ? 3 : 4),
          ),
        ),
        child: isMobile
            // Mobile: Stacked layout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Avatar + Name + Log count
                  Row(
                    children: [
                      // User icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(26),
                          border: Border.all(color: AppColors.secondary.withAlpha(77)),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Text(
                          user.userName ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Log count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.list_alt,
                              size: 12,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.logCount ?? 0}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bottom row: ID and last seen
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ID: ${user.userId}',
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            color: AppColors.slate,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.slate.withAlpha(179),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(user.lastSeen),
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    ],
                  ),
                ],
              )
            // Desktop: Row layout
            : Row(
                children: [
                  // User icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(26),
                      border: Border.all(color: AppColors.secondary.withAlpha(77)),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'ID: ${user.userId}',
                                style: const TextStyle(
                                  fontFamily: 'Urbanist',
                                  color: AppColors.slate,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: user.userId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Copied: ${user.userId}',
                                      style: const TextStyle(fontFamily: 'Urbanist'),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppColors.secondary,
                                    behavior: SnackBarBehavior.floating,
                                    width: 300,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: AppColors.slate.withAlpha(179),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.list_alt,
                            size: 16,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${user.logCount ?? 0}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LOGS',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.slate,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateFormat.format(user.lastSeen),
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 13,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
