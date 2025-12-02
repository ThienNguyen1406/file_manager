import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/drive_folder.dart';
import '../providers/drive_provider.dart';

class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    this.onTap,
  });

  final DriveFolder folder;
  final VoidCallback? onTap;

  void _showMenu(BuildContext context) {
    final provider = context.read<DriveProvider>();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                folder.isFavorite 
                    ? Icons.favorite 
                    : Icons.favorite_border,
                color: folder.isFavorite ? Colors.red : null,
              ),
              title: Text(folder.isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích'),
              onTap: () {
                provider.toggleFavoriteFolder(folder.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, DriveProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thư mục'),
        content: Text('Bạn có chắc chắn muốn xóa "${folder.name}"? Thư mục sẽ được chuyển vào thùng rác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteFolder(folder.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã chuyển vào thùng rác')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: folder.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(folder.icon, color: AppColors.primaryDark),
              const Spacer(),
              IconButton(
                icon: Icon(
                  folder.isFavorite 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                  color: folder.isFavorite 
                      ? Colors.red 
                      : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  final provider = context.read<DriveProvider>();
                  provider.toggleFavoriteFolder(folder.id);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _showMenu(context),
                icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            folder.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${folder.fileCount} tập tin • ${folder.storageUsedGb.toStringAsFixed(1)} GB',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      ),
    );
  }
}

