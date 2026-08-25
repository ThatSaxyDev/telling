class Organization {
  final String id;
  final String name;
  final String slug;
  final String plan;
  final String role;
  final String? inviteCode;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.plan,
    required this.role,
    this.inviteCode,
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
    );
  }
}

class OrganizationMember {
  final String id;
  final String name;
  final String email;
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
      email: json['email'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
