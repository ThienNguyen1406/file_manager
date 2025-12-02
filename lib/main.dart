import 'package:file_manager/page/login/login_page.dart';
import 'package:file_manager/page/main_navigator.dart';
import 'package:file_manager/providers/auth_provider.dart';
import 'package:file_manager/providers/drive_provider.dart';
import 'package:file_manager/providers/remote_data_provider.dart';
import 'package:file_manager/services/api_client.dart';
import 'package:file_manager/services/storage_service.dart';
import 'package:file_manager/services/uaa_service.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
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
    final storageService = StorageService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider(uaaService, storageService);
            // Load token khi khởi động (async, không block)
            authProvider.initialize();
            return authProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final driveProvider = DriveProvider(storageService);
            // Load dữ liệu khi khởi động (async, không block)
            driveProvider.initialize();
            return driveProvider;
          },
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
        // Đảm bảo không có initial route khác
        initialRoute: null,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastToken;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (kDebugMode) {
      debugPrint(
          '🔄 AuthWrapper rebuild: isAuthenticated=${authProvider.isAuthenticated}, token=${authProvider.token != null ? "exists" : "null"}');
    }

    // Kiểm tra nếu token invalid, tự động logout
    final remoteData = context.watch<RemoteDataProvider>();
    if (remoteData.hasInvalidToken && authProvider.isAuthenticated) {
      if (kDebugMode) {
        debugPrint('🔴 AuthWrapper: Token invalid, auto logging out...');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthProvider>().logout();
          context.read<DriveProvider>().clearAllData();
          context.read<RemoteDataProvider>().reset();
        }
      });
      // Tạm thời hiển thị loading hoặc LoginPage
      return const LoginPage();
    }

    // Nếu đã đăng nhập, hiển thị MainNavigator
    if (authProvider.isAuthenticated) {
      // Load remote data khi đã đăng nhập (chỉ một lần khi token thay đổi)
      final token = authProvider.token;
      if (token != null && _lastToken != token) {
        _lastToken = token;
        if (kDebugMode) {
          debugPrint('✅ AuthWrapper: Loading remote data with new token');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<RemoteDataProvider>().loadRemoteData(token);
          }
        });
      }
      return const MainNavigator();
    }

    // Reset token khi logout
    if (_lastToken != null) {
      if (kDebugMode) {
        debugPrint('🔴 AuthWrapper: User logged out, resetting...');
      }
      _lastToken = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<RemoteDataProvider>().reset();
        }
      });
    }

    // Nếu chưa đăng nhập, hiển thị LoginPage
    if (kDebugMode) {
      debugPrint('📱 AuthWrapper: Showing LoginPage');
    }
    return const LoginPage();
  }
}
