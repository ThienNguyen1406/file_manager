import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.usedStorage,
    required this.totalStorage,
  });

  final String currentRoute;
  final Function(String) onNavigate;
  final double usedStorage;
  final double totalStorage;

  @override
  Widget build(BuildContext context) {
    final storagePercent = (usedStorage / totalStorage).clamp(0.0, 1.0);
    final storageUsedMB = (usedStorage * 1024).toStringAsFixed(0);

    return Drawer(
      child: Column(
        children: [
          // Header với storage info
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${storageUsedMB}MB',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: storagePercent,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${usedStorage.toStringAsFixed(1)} GB / ${totalStorage.toStringAsFixed(0)} GB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      '${(storagePercent * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home,
                  label: 'Trang chủ',
                  isActive: currentRoute == '/home',
                  onTap: () => onNavigate('/home'),
                ),
                _DrawerItem(
                  icon: Icons.folder,
                  label: 'Tệp tin của tôi',
                  isActive: currentRoute == '/my-files',
                  onTap: () => onNavigate('/my-files'),
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Được chia sẻ với tôi',
                  isActive: currentRoute == '/shared',
                  onTap: () => onNavigate('/shared'),
                ),
                _DrawerItem(
                  icon: Icons.favorite_border,
                  label: 'Yêu thích',
                  isActive: currentRoute == '/favorites',
                  onTap: () => onNavigate('/favorites'),
                ),
                _DrawerItem(
                  icon: Icons.delete_outline,
                  label: 'Thùng rác',
                  isActive: currentRoute == '/trash',
                  onTap: () => onNavigate('/trash'),
                ),
                const Divider(height: 32),
                _ExpandableSection(
                  title: 'Không gian lưu trữ của tôi',
                  icon: Icons.storage_outlined,
                  children: [
                    _StorageItem(
                      icon: Icons.account_circle,
                      label: 'TrungLM',
                      color: AppColors.primary,
                    ),
                    // Có thể thêm nhiều storage items khác
                  ],
                ),
                _ExpandableSection(
                  title: 'Không gian lưu trữ được chia sẻ',
                  icon: Icons.folder_shared_outlined,
                  children: [
                    // Có thể thêm shared storage items
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                      child: Text(
                        'Chưa có không gian được chia sẻ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Settings
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.grey[600]),
            title: Text(
              'Cài đặt',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () => onNavigate('/settings'),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : Colors.grey[600],
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColors.primaryDark : Colors.black87,
            ),
      ),
      tileColor: isActive
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      onTap: onTap,
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(widget.icon, color: Colors.grey[600]),
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey[600],
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }
}

class _StorageItem extends StatelessWidget {
  const _StorageItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {},
      ),
    );
  }
}

