import 'package:flutter/material.dart';

class DriveFolder {
  DriveFolder({
    required this.id,
    required this.name,
    required this.fileCount,
    required this.storageUsedGb,
    required this.color,
    required this.icon,
    this.parentId,
    this.isFavorite = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final int fileCount;
  final double storageUsedGb;
  final Color color;
  final IconData icon;
  final String? parentId; // ID của folder cha, null nếu là root folder
  bool isFavorite;
  bool isDeleted;
  DateTime? deletedAt;

  bool get isRoot => parentId == null || parentId!.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fileCount': fileCount,
      'storageUsedGb': storageUsedGb,
      'color': color.value, // Lưu color value
      'icon': icon.codePoint, // Lưu icon codePoint
      'iconFontFamily': icon.fontFamily,
      'iconPackage': icon.fontPackage,
      'parentId': parentId,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DriveFolder.fromJson(Map<String, dynamic> json) {
    return DriveFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      fileCount: json['fileCount'] as int,
      storageUsedGb: (json['storageUsedGb'] as num).toDouble(),
      color: Color(json['color'] as int),
      icon: IconData(
        json['icon'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconPackage'] as String?,
      ),
      parentId: json['parentId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  DriveFolder copyWith({
    String? id,
    String? name,
    int? fileCount,
    double? storageUsedGb,
    Color? color,
    IconData? icon,
    String? parentId,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return DriveFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      fileCount: fileCount ?? this.fileCount,
      storageUsedGb: storageUsedGb ?? this.storageUsedGb,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
