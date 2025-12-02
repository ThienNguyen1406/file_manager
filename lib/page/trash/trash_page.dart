import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/empty_state.dart';
import '../../components/folder_card.dart';
import '../../constants/app_colors.dart';
import '../../models/drive_folder.dart';
import '../../models/drive_file.dart';
import '../../providers/drive_provider.dart';

class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  void _showFolderMenu(BuildContext context, DriveProvider provider, DriveFolder folder) {
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
              leading: const Icon(Icons.restore, color: AppColors.primary),
              title: const Text('Khôi phục'),
              onTap: () {
                Navigator.pop(context);
                provider.restoreFolder(folder.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã khôi phục thư mục')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Xóa vĩnh viễn'),
              onTap: () {
                Navigator.pop(context);
                _confirmPermanentDeleteFolder(context, provider, folder);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmPermanentDeleteFolder(BuildContext context, DriveProvider provider, DriveFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vĩnh viễn'),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn "${folder.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.permanentDeleteFolder(folder.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa vĩnh viễn')),
              );
            },
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showFileMenu(BuildContext context, DriveProvider provider, DriveFile file) {
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
              leading: const Icon(Icons.restore, color: AppColors.primary),
              title: const Text('Khôi phục'),
              onTap: () {
                Navigator.pop(context);
                provider.restoreFile(file.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã khôi phục tập tin')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Xóa vĩnh viễn'),
              onTap: () {
                Navigator.pop(context);
                _confirmPermanentDeleteFile(context, provider, file);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmPermanentDeleteFile(BuildContext context, DriveProvider provider, DriveFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vĩnh viễn'),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn "${file.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              provider.permanentDeleteFile(file.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa vĩnh viễn')),
              );
            },
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriveProvider>(
      builder: (context, provider, _) {
        final trashedFolders = provider.trashedFolders;
        final trashedFiles = provider.trashedFiles;
        final isEmpty = trashedFolders.isEmpty && trashedFiles.isEmpty;

        return Scaffold(
          body: isEmpty
              ? EmptyState(
                  icon: Icons.delete_outline,
                  title: 'Thùng rác trống',
                  subtitle: 'Các mục đã xóa sẽ xuất hiện ở đây',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (trashedFolders.isNotEmpty) ...[
                        Text(
                          'Thư mục đã xóa',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final folder = trashedFolders[index];
                            return GestureDetector(
                              onLongPress: () => _showFolderMenu(context, provider, folder),
                              child: Stack(
                                children: [
                                  FolderCard(
                                    folder: folder,
                                    onTap: null, // Không cho mở folder đã xóa
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.more_vert, 
                                          color: AppColors.textSecondary, size: 20),
                                      onPressed: () => _showFolderMenu(context, provider, folder),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          itemCount: trashedFolders.length,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (trashedFiles.isNotEmpty) ...[
                        Text(
                          'Tập tin đã xóa',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final file = trashedFiles[index];
                            return GestureDetector(
                              onLongPress: () => _showFileMenu(context, provider, file),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
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
                                      child: Icon(file.icon,
                                          color: AppColors.primaryDark),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${file.owner} • ${file.updatedAt}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert,
                                          color: AppColors.textSecondary),
                                      onPressed: () =>
                                          _showFileMenu(context, provider, file),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: trashedFiles.length,
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

