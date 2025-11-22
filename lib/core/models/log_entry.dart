class LogEntry {
  final int id;
  final String type;
  final String level;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? device;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? sessionId;

  LogEntry({
    required this.id,
    required this.type,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.metadata,
    this.device,
    this.userId,
    this.userName,
    this.userEmail,
    this.sessionId,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      type: json['type'],
      level: json['level'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      stackTrace: json['stackTrace'],
      metadata: json['metadata'],
      device: json['device'],
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      sessionId: json['sessionId'],
    );
  }
}
