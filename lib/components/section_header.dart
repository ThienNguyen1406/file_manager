import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/drive_provider.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.showViewToggle = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final bool showViewToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (showViewToggle)
          Consumer<DriveProvider>(
            builder: (context, provider, _) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.grid_view,
                        color: provider.viewMode == ViewMode.grid
                            ? AppColors.primary
                            : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => provider.setViewMode(ViewMode.grid),
                      tooltip: 'Chế độ lưới',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.view_list,
                        color: provider.viewMode == ViewMode.list
                            ? AppColors.primary
                            : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => provider.setViewMode(ViewMode.list),
                      tooltip: 'Chế độ danh sách',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
        if (actionLabel != null) ...[
          if (showViewToggle) const SizedBox(width: 8),
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

