import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SearchableUserDropdown extends StatefulWidget {
  final String? selectedUserId;
  final List<Map<String, dynamic>> users;
  final Function(String?) onChanged;

  const SearchableUserDropdown({
    super.key,
    this.selectedUserId,
    required this.users,
    required this.onChanged,
  });

  @override
  State<SearchableUserDropdown> createState() => _SearchableUserDropdownState();
}

class _SearchableUserDropdownState extends State<SearchableUserDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Positioned overlay using CompositedTransformFollower for accurate alignment
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  child: Container(
                    width: 280,
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      border: Border.all(
                        color: AppColors.slate.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) {
                              setState(() {
                                // Rebuild to filter users
                              });
                              _overlayEntry?.markNeedsBuild();
                            },
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by name or ID...',
                              hintStyle: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.slate,
                                fontSize: 10,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.slate,
                                size: 16,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: AppColors.slate.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: AppColors.slate.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Divider(
                          color: AppColors.slate.withOpacity(0.3),
                          height: 1,
                        ),

                        // User list
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              _buildUserOption(null, 'ALL USERS'),
                              ..._getFilteredUsers().map((user) {
                                final userId = user['userId'] as String?;
                                final userName =
                                    user['userName'] as String? ??
                                    userId ??
                                    'Unknown';
                                return _buildUserOption(userId, userName);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return widget.users;

    return widget.users.where((user) {
      final userId = (user['userId'] as String? ?? '').toLowerCase();
      final userName = (user['userName'] as String? ?? '').toLowerCase();
      return userId.contains(query) || userName.contains(query);
    }).toList();
  }

  Widget _buildUserOption(String? userId, String label) {
    final isSelected = widget.selectedUserId == userId;

    return InkWell(
      onTap: () {
        widget.onChanged(userId);
        _searchController.clear();
        _removeOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
            if (isSelected) const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (widget.selectedUserId == null) return 'ALL USERS';
    
    final user = widget.users.firstWhere(
      (u) => u['userId'] == widget.selectedUserId,
      orElse: () => {},
    );
    
    return user['userName'] as String? ?? user['userId'] as String? ?? 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            border: Border.all(
              color: _isOpen 
                  ? AppColors.primary 
                  : AppColors.slate.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getDisplayText(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: widget.selectedUserId == null ? AppColors.slate : AppColors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: AppColors.secondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
