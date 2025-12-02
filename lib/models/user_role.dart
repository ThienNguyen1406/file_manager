class UserRole {
  UserRole({
    required this.id,
    required this.email,
    required this.phone,
    required this.personalName,
    required this.orgIn,
    required this.orgName,
    required this.custId,
  });

  final String id;
  final String email;
  final String phone;
  final String personalName;
  final String orgIn;
  final String orgName;
  final int custId;

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      personalName: json['personalName'] as String? ?? '',
      orgIn: json['orgIn'] as String? ?? '',
      orgName: json['orgName'] as String? ?? '',
      custId: json['custId'] as int? ?? 0,
    );
  }
}

