import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/drive_folder.dart';
import '../providers/drive_provider.dart';

class FolderTile extends StatelessWidget {
  const FolderTile({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: folder.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                folder.icon,
                color: AppColors.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${folder.fileCount} tập tin • ${folder.storageUsedGb.toStringAsFixed(1)} GB',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (folder.isFavorite)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showMenu(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

