import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/menu_view.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.menus,
    this.emptyMessage = 'Không có dịch vụ nào',
  });

  final List<MenuView> menus;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🔧 ServiceGrid building with ${menus.length} menus');
      for (var i = 0; i < menus.length; i++) {
        debugPrint('   Menu $i: ${menus[i].title}, activated: ${menus[i].activated}');
      }
    }
    
    if (menus.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ ServiceGrid: menus is empty, showing empty message');
      }
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      );
    }

    if (kDebugMode) {
      debugPrint('✅ ServiceGrid: rendering ${menus.length} service cards');
    }
    
    if (kDebugMode) {
      debugPrint('📐 ServiceGrid: menus.length = ${menus.length}');
    }
    
    // Dùng GridView giống như các GridView khác trong codebase
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Test widget để đảm bảo render
        if (kDebugMode)
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.purple.withValues(alpha: 0.2),
            child: Text(
              'SERVICEGRID: ${menus.length} items',
              style: const TextStyle(fontSize: 10, color: Colors.purple),
            ),
          ),
        GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        if (kDebugMode) {
          debugPrint('🎴 Building service card $index/${menus.length - 1}: ${menus[index].title}');
        }
        try {
          final card = _ServiceCard(menu: menus[index]);
          if (kDebugMode && index == 0) {
            debugPrint('✅ First card built successfully');
          }
          return card;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Error building service card $index: $e');
            debugPrint('Stack trace: $stackTrace');
          }
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${menus[index].title}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
      },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.menu});

  final MenuView menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: menu.isActivated
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: menu.isActivated
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: menu.isActivated
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getServiceIcon(menu.nameId),
              color: menu.isActivated
                  ? AppColors.primary
                  : Colors.grey[600],
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            menu.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: menu.isActivated
                      ? AppColors.primaryDark
                      : Colors.grey[700],
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: menu.isActivated
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              menu.isActivated ? 'Đã kích hoạt' : 'Chưa kích hoạt',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: menu.isActivated
                    ? AppColors.primary
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String nameId) {
    if (nameId.contains('active') || nameId.contains('drive')) {
      return Icons.cloud_outlined;
    }
    if (nameId.contains('document')) {
      return Icons.description_outlined;
    }
    if (nameId.contains('share')) {
      return Icons.share_outlined;
    }
    return Icons.apps_outlined;
  }
}

