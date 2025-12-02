import 'package:flutter/material.dart';

enum DriveFileType { doc, sheet, slide, pdf, image, video }

class DriveFile {
  DriveFile({
    required this.id,
    required this.name,
    required this.owner,
    required this.updatedAt,
    required this.sizeLabel,
    required this.type,
    required this.icon,
    required this.color,
    this.isStarred = false,
    this.isFavorite = false,
    this.folderId,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String owner;
  final String updatedAt;
  final String sizeLabel;
  final DriveFileType type;
  final IconData icon;
  final Color color;
  bool isStarred;
  bool isFavorite;
  final String? folderId; // ID của folder chứa file này, null nếu ở root
  bool isDeleted;
  DateTime? deletedAt;

  bool matchesQuery(String query) =>
      query.isEmpty || name.toLowerCase().contains(query.toLowerCase());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'updatedAt': updatedAt,
      'sizeLabel': sizeLabel,
      'type': type.name,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconPackage': icon.fontPackage,
      'color': color.value,
      'isStarred': isStarred,
      'isFavorite': isFavorite,
      'folderId': folderId,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DriveFile.fromJson(Map<String, dynamic> json) {
    return DriveFile(
      id: json['id'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
      updatedAt: json['updatedAt'] as String,
      sizeLabel: json['sizeLabel'] as String,
      type: DriveFileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DriveFileType.doc,
      ),
      icon: IconData(
        json['icon'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconPackage'] as String?,
      ),
      color: Color(json['color'] as int),
      isStarred: json['isStarred'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      folderId: json['folderId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }
}
