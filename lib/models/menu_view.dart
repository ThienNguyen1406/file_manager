class MenuView {
  MenuView({
    required this.menuId,
    required this.menuParentId,
    required this.title,
    required this.serviceId,
    required this.serviceName,
    required this.activated,
    required this.nameId,
  });

  final int menuId;
  final int menuParentId;
  final String title;
  final int serviceId;
  final String serviceName;
  final int activated;
  final String nameId;

  factory MenuView.fromJson(Map<String, dynamic> json) {
    return MenuView(
      menuId: json['menuId'] as int? ?? 0,
      menuParentId: json['menuParentId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      serviceId: json['serviceId'] as int? ?? 0,
      serviceName: json['serviceName'] as String? ?? '',
      activated: json['activated'] as int? ?? 0,
      nameId: json['nameId'] as String? ?? '',
    );
  }

  bool get isActivated => activated == 1;
}

