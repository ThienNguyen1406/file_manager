import 'package:flutter/material.dart';

class DriveFolder {
  const DriveFolder({
    required this.id,
    required this.name,
    required this.fileCount,
    required this.storageUsedGb,
    required this.color,
    required this.icon,
    this.parentId,
  });

  final String id;
  final String name;
  final int fileCount;
  final double storageUsedGb;
  final Color color;
  final IconData icon;
  final String? parentId; // ID của folder cha, null nếu là root folder

  bool get isRoot => parentId == null || parentId!.isEmpty;
}

