import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class SharedPage extends StatelessWidget {
  const SharedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Được chia sẻ với tôi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Chưa có tệp tin nào được chia sẻ'),
        ),
      ),
    );
  }
}

