class Project {
  final String id;
  final String name;
  final String apiKey;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.apiKey,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      apiKey: json['apiKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
