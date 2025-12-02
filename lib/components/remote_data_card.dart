import 'dart:convert';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/account_info.dart';
import '../models/menu_view.dart';
import '../models/user_role.dart';
import 'account_info_card.dart';
import 'menu_view_card.dart';
import 'user_role_card.dart';

class RemoteDataCard extends StatelessWidget {
  const RemoteDataCard({
    super.key,
    required this.title,
    required this.data,
    this.description,
  });

  final String title;
  final dynamic data;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (data == null) {
      return const Text(
        'Chưa có dữ liệu',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    
    // Hiển thị MenuViews
    if (data is List<MenuView>) {
      final menuViews = data as List<MenuView>;
      if (menuViews.isEmpty) {
        return const Text(
          'Không có menu nào',
          style: TextStyle(color: AppColors.textSecondary),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số lượng: ${menuViews.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...menuViews.map((menu) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MenuViewCard(menuView: menu),
              )),
        ],
      );
    }
    
    // Hiển thị AccountInfo
    if (data is AccountInfo) {
      return AccountInfoCard(accountInfo: data as AccountInfo);
    }
    
    // Hiển thị UserRoles
    if (data is List<UserRole>) {
      final userRoles = data as List<UserRole>;
      if (userRoles.isEmpty) {
        return const Text(
          'Không có user role nào',
          style: TextStyle(color: AppColors.textSecondary),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số lượng: ${userRoles.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...userRoles.map((role) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: UserRoleCard(userRole: role),
              )),
        ],
      );
    }
    
    // Fallback: hiển thị JSON cho các loại khác
    if (data is List) {
      final count = data.length;
      final first = count > 0 ? data.first : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Số lượng: $count'),
          if (first != null) ...[
            const SizedBox(height: 6),
            _JsonPreview(value: first),
          ]
        ],
      );
    }
    if (data is Map<String, dynamic>) {
      return _JsonPreview(value: data);
    }
    return Text('$data');
  }
}

class _JsonPreview extends StatelessWidget {
  const _JsonPreview({required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final encoder = const JsonEncoder.withIndent('  ');
    final text = encoder.convert(value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 8,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

