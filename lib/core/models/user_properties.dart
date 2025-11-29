class UserProperties {
  final String userId;
  final Map<String, dynamic> properties;
  final DateTime updatedAt;

  UserProperties({
    required this.userId,
    required this.properties,
    required this.updatedAt,
  });

  factory UserProperties.fromJson(Map<String, dynamic> json) {
    return UserProperties(
      userId: json['userId'] as String,
      properties: json['properties'] as Map<String, dynamic>,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'properties': properties,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
