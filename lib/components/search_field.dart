import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class DriveSearchField extends StatelessWidget {
  const DriveSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm trong Drive',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: value.isEmpty
            ? IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune, color: AppColors.textSecondary),
              )
            : IconButton(
                onPressed: () => onChanged(''),
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
      ),
    );
  }
}

