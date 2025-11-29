class User {
  final String userId;
  final String? userName;
  final String? userEmail;
  final DateTime lastSeen;
  final int? logCount;

  User({
    required this.userId,
    this.userName,
    this.userEmail,
    required this.lastSeen,
    this.logCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? 'unknown',
      userName: json['userName'],
      userEmail: json['userEmail'],
      lastSeen: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : DateTime.now(),
      logCount: json['logCount'] ?? 0,
    );
  }
}

class UserStats {
  final int totalLogs;
  final int errorCount;
  final int sessionCount;
  final DateTime lastActive;

  UserStats({
    required this.totalLogs,
    required this.errorCount,
    required this.sessionCount,
    required this.lastActive,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalLogs: json['totalLogs'],
      errorCount: json['errorCount'],
      sessionCount: json['sessionCount'],
      lastActive: DateTime.parse(json['lastActive']),
    );
  }
}

class UserSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final int eventCount;

  UserSession({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.eventCount,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      durationSeconds: json['durationSeconds'],
      eventCount: json['eventCount'],
    );
  }
  
  Duration get duration => Duration(seconds: durationSeconds);
}
