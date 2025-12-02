import 'package:file_manager/page/login/login_page.dart';
import 'package:file_manager/page/main_navigator.dart';
import 'package:file_manager/providers/auth_provider.dart';
import 'package:file_manager/providers/drive_provider.dart';
import 'package:file_manager/providers/remote_data_provider.dart';
import 'package:file_manager/services/api_client.dart';
import 'package:file_manager/services/uaa_service.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo services
    final apiClient = ApiClient();
    final uaaService = UaaService(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(uaaService),
        ),
        ChangeNotifierProvider(
          create: (_) => DriveProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RemoteDataProvider(uaaService),
        ),
      ],
      child: MaterialApp(
        title: 'Green Drive',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Nếu đã đăng nhập, hiển thị MainNavigator
    if (authProvider.isAuthenticated) {
      // Load remote data khi đã đăng nhập
      final token = authProvider.token;
      if (token != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<RemoteDataProvider>().loadRemoteData(token);
        });
      }
      return const MainNavigator();
    }

    // Nếu chưa đăng nhập, hiển thị LoginPage
    return const LoginPage();
  }
}
