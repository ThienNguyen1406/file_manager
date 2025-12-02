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
}

