import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/menu_view.dart';

class MenuViewCard extends StatelessWidget {
  const MenuViewCard({
    super.key,
    required this.menuView,
  });

  final MenuView menuView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: menuView.isActivated
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: menuView.isActivated
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  menuView.isActivated
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: menuView.isActivated
                      ? AppColors.primary
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  menuView.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Menu ID', value: '${menuView.menuId}'),
          if (menuView.menuParentId > 0)
            _InfoRow(label: 'Menu Parent ID', value: '${menuView.menuParentId}'),
          _InfoRow(label: 'Service ID', value: '${menuView.serviceId}'),
          _InfoRow(label: 'Service Name', value: menuView.serviceName),
          _InfoRow(label: 'Name ID', value: menuView.nameId),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: menuView.isActivated
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              menuView.isActivated ? 'Đã kích hoạt' : 'Chưa kích hoạt',
              style: TextStyle(
                fontSize: 11,
                color: menuView.isActivated
                    ? AppColors.primary
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

