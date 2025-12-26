/// Notification settings model for per-project preferences
class NotificationSettings {
  final bool pushEnabled;
  final String pushMinSeverity;
  final String pushDigestFrequency;
  final bool emailEnabled;
  final bool emailInstantAlerts;
  final String emailDigestFrequency;
  final String timezone;

  const NotificationSettings({
    this.pushEnabled = true,
    this.pushMinSeverity = 'error',
    this.pushDigestFrequency = 'both',
    this.emailEnabled = true,
    this.emailInstantAlerts = true,
    this.emailDigestFrequency = 'both',
    this.timezone = 'UTC',
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    String? pushMinSeverity,
    String? pushDigestFrequency,
    bool? emailEnabled,
    bool? emailInstantAlerts,
    String? emailDigestFrequency,
    String? timezone,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      pushMinSeverity: pushMinSeverity ?? this.pushMinSeverity,
      pushDigestFrequency: pushDigestFrequency ?? this.pushDigestFrequency,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailInstantAlerts: emailInstantAlerts ?? this.emailInstantAlerts,
      emailDigestFrequency: emailDigestFrequency ?? this.emailDigestFrequency,
      timezone: timezone ?? this.timezone,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      pushMinSeverity: json['pushMinSeverity'] as String? ?? 'error',
      pushDigestFrequency: json['pushDigestFrequency'] as String? ?? 'both',
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      emailInstantAlerts: json['emailInstantAlerts'] as bool? ?? true,
      emailDigestFrequency: json['emailDigestFrequency'] as String? ?? 'both',
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'pushMinSeverity': pushMinSeverity,
      'pushDigestFrequency': pushDigestFrequency,
      'emailEnabled': emailEnabled,
      'emailInstantAlerts': emailInstantAlerts,
      'emailDigestFrequency': emailDigestFrequency,
      'timezone': timezone,
    };
  }
}
