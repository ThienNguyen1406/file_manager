import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/drive_file.dart';
import '../providers/drive_provider.dart';

class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.file});

  final DriveFile file;

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
                file.isFavorite 
                    ? Icons.favorite 
                    : Icons.favorite_border,
                color: file.isFavorite ? Colors.red : null,
              ),
              title: Text(file.isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích'),
              onTap: () {
                provider.toggleFavoriteFile(file.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                file.isStarred ? Icons.star : Icons.star_border_rounded,
                color: file.isStarred ? Colors.amber : null,
              ),
              title: Text(file.isStarred ? 'Bỏ đánh dấu sao' : 'Đánh dấu sao'),
              onTap: () {
                provider.toggleStar(file.id);
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
        title: const Text('Xóa tập tin'),
        content: Text('Bạn có chắc chắn muốn xóa "${file.name}"? Tập tin sẽ được chuyển vào thùng rác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteFile(file.id);
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
    final provider = context.read<DriveProvider>();
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: file.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(file.icon, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${file.owner} • ${file.updatedAt}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        file.isFavorite 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        color: file.isFavorite 
                            ? Colors.red 
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleFavoriteFile(file.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        file.isStarred ? Icons.star : Icons.star_border_rounded,
                        color: file.isStarred ? Colors.amber : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleStar(file.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  file.sizeLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onPressed: () => _showMenu(context),
            ),
          ],
        ),
      ),
    );
  }
}

