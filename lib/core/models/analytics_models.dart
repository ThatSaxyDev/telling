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
      totalLogs: json['totalLogs'],
      errorCount: json['errorCount'],
      errorRate: double.parse(json['errorRate'].toString()),
      activeSessions: json['activeSessions'],
      activeUsers: json['activeUsers'],
      logsTrend: json['logsTrend'],
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
    return LogTimelinePoint(
      timestamp: DateTime.parse(json['timestamp']),
      counts: Map<String, int>.from(json['counts']),
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
      level: json['level'],
      count: json['count'],
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
      message: json['message'],
      count: json['count'],
      lastSeen: DateTime.parse(json['lastSeen']),
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
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      logCount: json['logCount'],
      lastActive: DateTime.parse(json['lastActive']),
    );
  }
}
