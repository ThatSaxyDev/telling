class Organization {
  final String id;
  final String name;
  final String slug;
  final String plan;
  final String role;
  final String? inviteCode;
  final DateTime? inviteCodeExpiresAt;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.plan,
    required this.role,
    this.inviteCode,
    this.inviteCodeExpiresAt,
  });

  bool get isOwner => role == 'owner';

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      plan: json['plan'] as String? ?? 'free',
      role: json['role'] as String,
      inviteCode: json['inviteCode'] as String?,
      inviteCodeExpiresAt: json['inviteCodeExpiresAt'] != null
          ? DateTime.tryParse(json['inviteCodeExpiresAt'] as String)
          : null,
    );
  }
}

class OrganizationMember {
  final String id;
  final String name;

  /// Only included in API responses for commanders.
  final String? email;
  final String role;
  final DateTime joinedAt;

  OrganizationMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
