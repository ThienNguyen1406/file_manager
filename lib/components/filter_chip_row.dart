import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/drive_provider.dart';

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriveProvider>();
    final filters = DriveFilter.values;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = provider.activeFilter == filter;
          return ChoiceChip(
            label: Text(filter.label),
            avatar: Icon(
              filter.icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            selected: isSelected,
            onSelected: (_) => provider.selectFilter(filter),
            selectedColor: AppColors.accent.withValues(alpha: 0.35),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: filters.length,
      ),
    );
  }
}

