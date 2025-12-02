import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/app_drawer.dart';
import '../constants/app_colors.dart';
import '../providers/drive_provider.dart';
import 'favorites/favorites_page.dart';
import 'home/home_page.dart';
import 'my_files/my_files_page.dart';
import 'shared/shared_page.dart';
import 'trash/trash_page.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  String _currentRoute = '/home';

  void _navigateTo(String route) {
    setState(() {
      _currentRoute = route;
    });
    Navigator.pop(context); // Đóng drawer
  }

  Widget _getCurrentPage() {
    switch (_currentRoute) {
      case '/home':
        return const HomePage();
      case '/my-files':
        return const MyFilesPage();
      case '/shared':
        return const SharedPage();
      case '/favorites':
        return const FavoritesPage();
      case '/trash':
        return const TrashPage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final driveProvider = context.watch<DriveProvider>();
    
    return Scaffold(
      drawer: AppDrawer(
        currentRoute: _currentRoute,
        onNavigate: _navigateTo,
        usedStorage: driveProvider.usedStorageGb,
        totalStorage: driveProvider.storageLimitGb,
      ),
      appBar: AppBar(
        title: _currentRoute == '/home'
            ? null
            : Text(_getAppBarTitle()),
        backgroundColor: _currentRoute == '/home'
            ? Colors.transparent
            : AppColors.primary,
        foregroundColor: _currentRoute == '/home'
            ? AppColors.primaryDark
            : Colors.white,
        elevation: _currentRoute == '/home' ? 0 : null,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: _currentRoute == '/home'
                  ? AppColors.primaryDark
                  : Colors.white,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _getCurrentPage(),
    );
  }
  
  String _getAppBarTitle() {
    switch (_currentRoute) {
      case '/my-files':
        return 'Tệp tin của tôi';
      case '/shared':
        return 'Được chia sẻ với tôi';
      case '/favorites':
        return 'Yêu thích';
      case '/trash':
        return 'Thùng rác';
      default:
        return 'Green Drive';
    }
  }
}

