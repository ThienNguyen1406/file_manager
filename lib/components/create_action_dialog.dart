import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum CreateAction { folder, upload, uploadFolder, sync, createSpace }

class CreateActionDialog extends StatelessWidget {
  const CreateActionDialog({super.key});

  static Future<CreateAction?> show(BuildContext context) {
    return showModalBottomSheet<CreateAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateActionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionTile(
                      icon: Icons.create_new_folder_outlined,
                      title: 'Thư mục mới',
                      subtitle: 'Tạo thư mục mới để tổ chức tài liệu',
                      color: AppColors.primary,
                      onTap: () => Navigator.pop(context, CreateAction.folder),
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.upload_file_outlined,
                      title: 'Tải tệp lên',
                      subtitle: 'Chọn file từ thiết bị để tải lên',
                      color: AppColors.primary,
                      onTap: () => Navigator.pop(context, CreateAction.upload),
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.folder_outlined,
                      title: 'Tải thư mục lên',
                      subtitle: 'Tải toàn bộ thư mục và nội dung',
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.pop(context, CreateAction.uploadFolder),
                    ),
                    const Divider(height: 24),
                    _ActionTile(
                      icon: Icons.sync_outlined,
                      title: 'Đồng bộ tài liệu',
                      subtitle: 'Đồng bộ dữ liệu từ server',
                      color: AppColors.primary,
                      onTap: () => Navigator.pop(context, CreateAction.sync),
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.dashboard_outlined,
                      title: 'Tạo không gian mới',
                      subtitle: 'Tạo không gian lưu trữ mới',
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.pop(context, CreateAction.createSpace),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
