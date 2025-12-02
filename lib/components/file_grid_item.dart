import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/drive_file.dart';
import '../providers/drive_provider.dart';

class FileGridItem extends StatelessWidget {
  const FileGridItem({super.key, required this.file});

  final DriveFile file;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DriveProvider>();
    return GestureDetector(
      onLongPress: () {
        // Show menu
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: file.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(file.icon, color: AppColors.primaryDark, size: 20),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    file.isFavorite 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                    color: file.isFavorite 
                        ? Colors.red 
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () => provider.toggleFavoriteFile(file.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              file.sizeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

