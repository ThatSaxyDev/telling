import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'shared/widgets/dashboard_layout.dart';
import 'shared/widgets/military_decorations.dart';
import 'shared/widgets/app_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _logs = [];
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    // Poll every 2 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchLogs());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/api/v1/logs'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _logs = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching logs: $e');
    }
  }

  Color _getLevelColor(String? level) {
    switch (level) {
      case 'error':
        return AppColors.error;
      case 'warning':
        return Colors.orange;
      default:
        return AppColors.white; // Info is white in this theme
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      header: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.radar, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                GlitchText(
                  text: 'TELLING // DASHBOARD',
                  style: AppTextStyles.headlineSmall,
                  glitchAmount: 2.0,
                ),
              ],
            ),
            AppButton(
              text: 'REFRESH',
              icon: Icons.refresh,
              isOutlined: true,
              onPressed: _fetchLogs,
            ),
          ],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.signal_wifi_off,
                    size: 48,
                    color: AppColors.slate,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO SIGNALS DETECTED',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: _logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                return _buildLogItem(log);
              },
            ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final level = log['level'] as String?;
    final type = log['type'] as String?;
    final message = log['message'] as String? ?? '';
    final timestamp =
        DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
    final device = log['device'] as Map<String, dynamic>?;
    
    final color = _getLevelColor(level);

    return MilitaryHoverContainer(
      onTap: () => _showLogDetails(log),
      baseColor: AppColors.tertiary,
      hoverColor: AppColors.darkSlate,
      showGrid: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Status Indicator
            Container(width: 4, height: 40, color: color),
            const SizedBox(width: 16),

            // Icon
            CornerBrackets(
              length: 6,
              thickness: 1,
              color: AppColors.slate,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  type == 'error' ? Icons.warning_amber : Icons.info_outline,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.toUpperCase(),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                      if (device != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '//',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${device['platform']} :: ${device['deviceModel']}'
                              .toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 800),
          child: MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            showGrid: true,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                color: AppColors.backgroundDark.withOpacity(0.95),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlitchText(
                          text: 'LOG DETAILS // ID: ${log['id']}',
                          style: AppTextStyles.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection('MESSAGE', log['message']),
                          _buildDetailSection(
                            'TYPE',
                            log['type']?.toString().toUpperCase() ?? 'UNKNOWN',
                          ),
                          _buildDetailSection(
                            'LEVEL',
                            log['level']?.toString().toUpperCase() ?? 'UNKNOWN',
                          ),
                          _buildDetailSection('TIMESTAMP', log['timestamp']),

                          if (log['stackTrace'] != null)
                            _buildDetailSection(
                              'STACK TRACE',
                              log['stackTrace'],
                              isCode: true,
                            ),

                          if (log['metadata'] != null)
                            _buildDetailSection(
                              'METADATA',
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(log['metadata']),
                              isCode: true,
                            ),

                          if (log['device'] != null)
                            _buildDetailSection(
                              'DEVICE INFO',
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(log['device']),
                              isCode: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String label,
    String? content, {
    bool isCode = false,
  }) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          if (isCode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Text(
                content,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  height: 1.5,
                ),
              ),
            )
          else
            Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
        ],
      ),
    );
  }
}

