import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/create_action_dialog.dart';
import '../../components/create_folder_dialog.dart';
import '../../components/drive_header.dart';
import '../../components/empty_state.dart';
import '../../components/file_grid_item.dart';
import '../../components/file_tile.dart';
import '../../components/filter_chip_row.dart';
import '../../components/folder_card.dart';
import '../../components/search_field.dart';
import '../../components/section_header.dart';
import '../../components/service_grid.dart';
import '../../models/drive_file.dart';
import '../../page/folder_detail/folder_detail_page.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drive_provider.dart';
import '../../providers/remote_data_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _lastToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRemoteData());
  }

  void _fetchRemoteData() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) {
      // Nếu chưa đăng nhập, reset data
      if (_lastToken != null) {
        context.read<RemoteDataProvider>().reset();
        _lastToken = null;
      }
      return;
    }

    // Chỉ gọi API nếu token thay đổi
    if (_lastToken != auth.token) {
      _lastToken = auth.token;
      context.read<RemoteDataProvider>().loadRemoteData(auth.token!);
    }
  }

  Future<void> _handleFloatingActionButton() async {
    final action = await CreateActionDialog.show(context);
    if (action == null || !mounted) return;

    final driveProvider = context.read<DriveProvider>();

    if (action == CreateAction.folder) {
      await _createFolder(driveProvider);
    } else if (action == CreateAction.upload) {
      await _uploadFile(driveProvider);
    }
  }

  Future<void> _createFolder(DriveProvider driveProvider,
      {String? parentId}) async {
    final folderName = await CreateFolderDialog.show(context);
    if (!mounted) return;
    if (folderName != null && folderName.isNotEmpty) {
      driveProvider.createFolder(folderName, parentId: parentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo thư mục "$folderName"'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  bool _matchesFilter(DriveFile file, DriveFilter filter) {
    switch (filter) {
      case DriveFilter.docs:
        return file.type == DriveFileType.doc || file.type == DriveFileType.pdf;
      case DriveFilter.sheets:
        return file.type == DriveFileType.sheet;
      case DriveFilter.slides:
        return file.type == DriveFileType.slide;
      case DriveFilter.media:
        return file.type == DriveFileType.image ||
            file.type == DriveFileType.video;
      case DriveFilter.shared:
        return file.owner != 'Bạn';
      case DriveFilter.all:
        return true;
    }
  }

  Future<void> _uploadFile(DriveProvider driveProvider,
      {String? folderId}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await driveProvider.uploadFile(file, folderId: folderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải lên "${result.files.single.name}"'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driveProvider = context.watch<DriveProvider>();
    final auth = context.watch<AuthProvider>();
    final remote = context.watch<RemoteDataProvider>();
    // Chỉ hiển thị root folders (không có parentId)
    final folders = driveProvider.getFoldersByParent(null);
    // Chỉ hiển thị root files (không có folderId)
    final files = driveProvider.getFilesByFolder(null).where((file) {
      final filterMatches = driveProvider.activeFilter == DriveFilter.all ||
          _matchesFilter(file, driveProvider.activeFilter);
      final searchMatches = file.matchesQuery(driveProvider.searchQuery);
      return filterMatches && searchMatches;
    }).toList();

    // Tự động gọi API khi có token mới (chỉ một lần)
    if (auth.isAuthenticated &&
        auth.token != null &&
        _lastToken != auth.token) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchRemoteData();
        }
      });
    }

    // Lấy thông tin user từ API
    String userName = 'Người dùng';
    String? userEmail;
    String? userOrgName;

    if (remote.accountInfo != null) {
      userName = remote.accountInfo!.fullName.isNotEmpty
          ? remote.accountInfo!.fullName
          : (remote.accountInfo!.firstName.isNotEmpty
              ? remote.accountInfo!.firstName
              : 'Người dùng');
      userEmail = remote.accountInfo!.email.isNotEmpty
          ? remote.accountInfo!.email
          : null;
      if (kDebugMode) {
        debugPrint('👤 Using AccountInfo: $userName, $userEmail');
      }
    } else if (remote.userRoles != null && remote.userRoles!.isNotEmpty) {
      final role = remote.userRoles!.first;
      userName =
          role.personalName.isNotEmpty ? role.personalName : 'Người dùng';
      userEmail = role.email.isNotEmpty ? role.email : null;
      userOrgName = role.orgName.isNotEmpty ? role.orgName : null;
      if (kDebugMode) {
        debugPrint('👤 Using UserRole: $userName, $userEmail, $userOrgName');
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ No user info available');
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleFloatingActionButton,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriveHeader(
                userName: userName,
                usedStorage: driveProvider.usedStorageGb,
                totalStorage: driveProvider.storageLimitGb,
                email: userEmail,
                orgName: userOrgName,
              ),
              const SizedBox(height: 24),
              DriveSearchField(
                value: driveProvider.searchQuery,
                onChanged: driveProvider.updateSearch,
              ),
              const SizedBox(height: 16),
              const FilterChipRow(),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Thư mục của bạn',
                actionLabel: folders.isNotEmpty ? 'Xem tất cả' : null,
                onActionTap: folders.isNotEmpty ? () {} : null,
              ),
              const SizedBox(height: 12),
              folders.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_outlined,
                      title: 'Chưa có thư mục',
                      subtitle: 'Tạo thư mục mới để tổ chức tài liệu của bạn',
                      actionLabel: 'Tạo thư mục',
                      onAction: () =>
                          _createFolder(driveProvider, parentId: null),
                    )
                  : GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) => FolderCard(
                        folder: folders[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderDetailPage(
                                folder: folders[index],
                              ),
                            ),
                          );
                        },
                      ),
                      itemCount: folders.length,
                    ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Tập tin gần đây',
                actionLabel: null, // Tạm thời ẩn "Sắp xếp" để nút toggle rõ hơn
                onActionTap: null,
                showViewToggle: files.isNotEmpty,
              ),
              const SizedBox(height: 12),
              files.isEmpty
                  ? EmptyState(
                      icon: Icons.insert_drive_file_outlined,
                      title: 'Chưa có tập tin',
                      subtitle: 'Tải file lên để bắt đầu lưu trữ',
                      actionLabel: 'Tải file lên',
                      onAction: () => _uploadFile(driveProvider),
                    )
                  : Consumer<DriveProvider>(
                      builder: (context, provider, _) {
                        if (provider.viewMode == ViewMode.grid) {
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) =>
                                FileGridItem(file: files[index]),
                            itemCount: files.length,
                          );
                        } else {
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) =>
                                FileTile(file: files[index]),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: files.length,
                          );
                        }
                      },
                    ),
              // Hiển thị dịch vụ dynamic nếu đã đăng nhập
              if (auth.isAuthenticated && auth.token != null) ...[
                const SizedBox(height: 28),
                // Sử dụng Builder để đảm bảo Consumer luôn rebuild
                Builder(
                  builder: (context) {
                    // Watch trực tiếp trong Builder
                    final remoteData = context.watch<RemoteDataProvider>();
                    if (kDebugMode) {
                      debugPrint('🔄 Builder rebuild - menuViews: ${remoteData.menuViews?.length ?? 0}');
                    }
                    
                    return Consumer<RemoteDataProvider>(
                      builder: (context, remoteData, _) {
                        if (kDebugMode) {
                          debugPrint('🔄 Consumer rebuild - menuViews: ${remoteData.menuViews?.length ?? 0}');
                        }
                    // Hiển thị loading
                    if (remoteData.isLoading) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // Hiển thị lỗi nếu có và chưa có data
                    if (remoteData.error != null &&
                        !remoteData.hasUserInfo &&
                        (remoteData.menuViews == null ||
                            remoteData.menuViews!.isEmpty)) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              remoteData.error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _fetchRemoteData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Debug: Log data để kiểm tra
                    if (kDebugMode) {
                      debugPrint('📊 RemoteData Status:');
                      debugPrint(
                          '  - menuViews: ${remoteData.menuViews?.length ?? 0}');
                      debugPrint(
                          '  - activatedMenus: ${remoteData.activatedMenus.length}');
                      debugPrint(
                          '  - inactiveMenus: ${remoteData.inactiveMenus.length}');
                      debugPrint(
                          '  - accountInfo: ${remoteData.accountInfo != null}');
                      debugPrint(
                          '  - userRoles: ${remoteData.userRoles?.length ?? 0}');
                      debugPrint('  - error: ${remoteData.error}');
                      debugPrint('  - isLoading: ${remoteData.isLoading}');
                      if (remoteData.menuViews != null &&
                          remoteData.menuViews!.isNotEmpty) {
                        for (var menu in remoteData.menuViews!) {
                          debugPrint(
                              '  - Menu: ${menu.title}, activated: ${menu.activated}, isActivated: ${menu.isActivated}');
                        }
                      }
                    }

                    // Hiển thị dịch vụ nếu có menuViews
                    final hasMenus = remoteData.menuViews != null &&
                        remoteData.menuViews!.isNotEmpty;
                    final hasActivated = remoteData.activatedMenus.isNotEmpty;
                    final hasInactive = remoteData.inactiveMenus.isNotEmpty;

                    if (kDebugMode) {
                      debugPrint(
                          '🎨 Render check: hasMenus=$hasMenus, hasActivated=$hasActivated, hasInactive=$hasInactive');
                    }

                    // Hiển thị dịch vụ nếu có menuViews
                    if (hasMenus) {
                      if (kDebugMode) {
                        debugPrint(
                            '✅ Rendering services section with ${remoteData.menuViews!.length} menus');
                        debugPrint('   - hasActivated: $hasActivated');
                        debugPrint('   - hasInactive: $hasInactive');
                      }

                      // Build widgets trước
                      final List<Widget> serviceWidgets = [];

                      if (!hasActivated && !hasInactive) {
                        if (kDebugMode) {
                          debugPrint(
                              '📦 Rendering all menus (${remoteData.menuViews!.length})');
                        }
                        serviceWidgets.add(
                          ServiceGrid(
                            menus: remoteData.menuViews!,
                            emptyMessage: 'Không có dịch vụ nào',
                          ),
                        );
                      } else {
                        if (hasActivated) {
                          if (kDebugMode) {
                            debugPrint(
                                '✅ Rendering activated menus (${remoteData.activatedMenus.length})');
                          }
                          serviceWidgets.addAll([
                            Text(
                              'Đã kích hoạt (${remoteData.activatedMenus.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ServiceGrid(
                              menus: remoteData.activatedMenus,
                              emptyMessage: 'Không có dịch vụ đã kích hoạt',
                            ),
                          ]);
                        }

                        if (hasInactive) {
                          if (kDebugMode) {
                            debugPrint(
                                '⚠️ Rendering inactive menus (${remoteData.inactiveMenus.length})');
                          }
                          if (hasActivated) {
                            serviceWidgets.add(const SizedBox(height: 24));
                          }
                          serviceWidgets.addAll([
                            Text(
                              'Chưa kích hoạt (${remoteData.inactiveMenus.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ServiceGrid(
                              key: ValueKey('inactive_menus_${remoteData.inactiveMenus.length}'),
                              menus: remoteData.inactiveMenus,
                              emptyMessage: 'Không có dịch vụ chưa kích hoạt',
                            ),
                          ]);
                        }
                      }

                      if (kDebugMode) {
                        debugPrint('📦 Building Column with ${serviceWidgets.length} widgets');
                        debugPrint('   Widget types: ${serviceWidgets.map((w) => w.runtimeType.toString()).join(", ")}');
                      }
                      
                      // Đảm bảo widget có key để Flutter rebuild đúng
                      return Column(
                        key: ValueKey('services_section_${remoteData.menuViews?.length ?? 0}'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SectionHeader(
                            title: 'Dịch vụ của tôi',
                            actionLabel: 'Làm mới',
                            onActionTap: _fetchRemoteData,
                          ),
                          const SizedBox(height: 12),
                          ...serviceWidgets,
                        ],
                      );
                    }

                    // Hiển thị thông báo nếu không có data
                    if (!hasMenus && !remoteData.isLoading) {
                      if (kDebugMode) {
                        debugPrint('❌ No menus to render, showing empty message');
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  'Không có dữ liệu dịch vụ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            if (remoteData.error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                remoteData.error!,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Chưa có dịch vụ nào được tìm thấy. Vui lòng thử lại.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _fetchRemoteData,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Tải lại dữ liệu'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                    },
                    );
                  },
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
