class AccountInfo {
  AccountInfo({
    required this.id,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.gender,
    this.address,
  });

  final int id;
  final String login;
  final String firstName;
  final String lastName;
  final String email;
  final String? gender;
  final String? address;

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['id'] as int? ?? 0,
      login: json['login'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String?,
      address: json['address'] as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

