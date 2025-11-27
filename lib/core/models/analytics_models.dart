class AnalyticsSummary {
  final int totalLogs;
  final int errorCount;
  final double errorRate;
  final int activeSessions;
  final int activeUsers;
  final int logsTrend; // Percentage change from previous period

  AnalyticsSummary({
    required this.totalLogs,
    required this.errorCount,
    required this.errorRate,
    required this.activeSessions,
    required this.activeUsers,
    required this.logsTrend,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalLogs: json['totalLogs'] ?? 0,
      errorCount: json['errorCount'] ?? 0,
      errorRate: json['errorRate'] != null
          ? double.parse(json['errorRate'].toString())
          : 0.0,
      activeSessions: json['activeSessions'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      logsTrend: json['logsTrend'] ?? 0,
    );
  }
}

class LogTimelinePoint {
  final DateTime timestamp;
  final Map<String, int> counts; // level -> count

  LogTimelinePoint({
    required this.timestamp,
    required this.counts,
  });

  factory LogTimelinePoint.fromJson(Map<String, dynamic> json) {
    // Handle actual backend format: {time: "...", count: 123, level: "info"}
    if (json.containsKey('time') && json.containsKey('count')) {
      final timestamp = json['time'] != null
          ? DateTime.parse(json['time'])
          : DateTime.now();

      final count = (json['count'] ?? 0) as int;
      final level = json['level'] as String?;

      return LogTimelinePoint(
        timestamp: timestamp,
        counts: {
          if (level != null) level.toLowerCase(): count else 'total': count,
        },
      );
    }
    
    // Handle expected format: {timestamp: "...", counts: {level: count}}
    return LogTimelinePoint(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      counts: json['counts'] != null
          ? Map<String, int>.from(
              json['counts'].map(
                (key, value) => MapEntry(key.toString(), (value ?? 0) as int),
              ),
            )
          : {},
    );
  }

  int get total => counts.values.fold(0, (sum, count) => sum + count);
}

class LogLevelStat {
  final String level;
  final int count;

  LogLevelStat({
    required this.level,
    required this.count,
  });

  factory LogLevelStat.fromJson(Map<String, dynamic> json) {
    return LogLevelStat(
      level: json['level'] ?? 'unknown',
      count: json['count'] ?? 0,
    );
  }
}

class TopErrorItem {
  final String message;
  final int count;
  final DateTime lastSeen;

  TopErrorItem({
    required this.message,
    required this.count,
    required this.lastSeen,
  });

  factory TopErrorItem.fromJson(Map<String, dynamic> json) {
    return TopErrorItem(
      message: json['message'] ?? 'Unknown error',
      count: json['count'] ?? 0,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
    );
  }
}

class ActiveUserStat {
  final String userId;
  final String? userName;
  final String? userEmail;
  final int logCount;
  final DateTime lastActive;

  ActiveUserStat({
    required this.userId,
    this.userName,
    this.userEmail,
    required this.logCount,
    required this.lastActive,
  });

  factory ActiveUserStat.fromJson(Map<String, dynamic> json) {
    return ActiveUserStat(
      userId: json['userId'] ?? 'unknown',
      userName: json['userName'],
      userEmail: json['userEmail'],
      logCount: json['logCount'] ?? 0,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : DateTime.now(),
    );
  }
}

class PerformanceMetricStats {
  final double avg;
  final double p50;
  final double p90;
  final double p95;
  final double p99;
  final int samples;

  PerformanceMetricStats({
    required this.avg,
    required this.p50,
    required this.p90,
    required this.p95,
    required this.p99,
    required this.samples,
  });

  factory PerformanceMetricStats.fromJson(Map<String, dynamic> json) {
    return PerformanceMetricStats(
      avg: (json['avg'] ?? 0).toDouble(),
      p50: (json['p50'] ?? 0).toDouble(),
      p90: (json['p90'] ?? 0).toDouble(),
      p95: (json['p95'] ?? 0).toDouble(),
      p99: (json['p99'] ?? 0).toDouble(),
      samples: json['samples'] ?? 0,
    );
  }
}

class PerformanceMetrics {
  final Map<String, PerformanceMetricStats> metrics;

  PerformanceMetrics({required this.metrics});

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    final metrics = <String, PerformanceMetricStats>{};
    if (json['metrics'] != null) {
      (json['metrics'] as Map<String, dynamic>).forEach((key, value) {
        metrics[key] = PerformanceMetricStats.fromJson(value);
      });
    }
    return PerformanceMetrics(metrics: metrics);
  }
}
