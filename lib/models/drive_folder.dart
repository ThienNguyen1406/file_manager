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

