import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'error':
        return Icons.error_outline;
      case 'analytics':
        return Icons.analytics_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telling Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No logs yet. Run the SDK to send some!'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final level = log['level'] as String?;
                    final type = log['type'] as String?;
                    final message = log['message'] as String? ?? '';
                    final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
                    final device = log['device'] as Map<String, dynamic>?;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getLevelColor(level).withOpacity(0.1),
                          child: Icon(_getTypeIcon(type), color: _getLevelColor(level)),
                        ),
                        title: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${timestamp.hour}:${timestamp.minute}:${timestamp.second} • $type',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (device != null)
                              Text(
                                '${device['platform']} • ${device['deviceModel']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(type?.toUpperCase() ?? 'LOG'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Message:', style: Theme.of(context).textTheme.labelLarge),
                                    Text(message),
                                    const SizedBox(height: 10),
                                    if (log['stackTrace'] != null) ...[
                                      Text('Stack Trace:', style: Theme.of(context).textTheme.labelLarge),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        color: Colors.grey.shade100,
                                        child: Text(
                                          log['stackTrace'],
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    Text('Metadata:', style: Theme.of(context).textTheme.labelLarge),
                                    Text(const JsonEncoder.withIndent('  ').convert(log)),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
