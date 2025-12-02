import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/create_action_dialog.dart';
import '../../components/create_folder_dialog.dart';
import '../../components/empty_state.dart';
import '../../components/file_grid_item.dart';
import '../../components/file_tile.dart';
import '../../components/filter_chip_row.dart';
import '../../components/folder_card.dart';
import '../../components/folder_tile.dart';
import '../../components/search_field.dart';
import '../../components/section_header.dart';
import '../../constants/app_colors.dart';
import '../../models/drive_file.dart';
import '../../page/folder_detail/folder_detail_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drive_provider.dart';

class StorageSpacePage extends StatefulWidget {
  const StorageSpacePage({super.key});

  @override
  State<StorageSpacePage> createState() => _StorageSpacePageState();
}

class _StorageSpacePageState extends State<StorageSpacePage> {
  String? _lastToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Delay để đảm bảo context đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDataFromApi(forceReload: true);
      }
    });
  }

  Future<void> _loadDataFromApi({bool forceReload = false}) async {
    if (!mounted) return;

    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated || auth.token == null) {
        if (kDebugMode) {
          debugPrint('⚠️ StorageSpacePage: Not authenticated');
        }
        return;
      }

      // Nếu force reload, bỏ qua check token
      if (!forceReload && _lastToken == auth.token) {
        if (kDebugMode) {
          debugPrint('⚠️ StorageSpacePage: Already loaded for this token');
        }
        return;
      }
      _lastToken = auth.token;

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      if (kDebugMode) {
        debugPrint(
            '🔄 StorageSpacePage: Loading data from API... (forceReload: $forceReload)');
      }

      await context.read<DriveProvider>().syncFromS3Api(auth.token!);

      if (kDebugMode) {
        debugPrint('✅ StorageSpacePage: Data loaded successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ StorageSpacePage: Error loading data from API: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Không crash app, chỉ log lỗi
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFloatingActionButton() async {
    final action = await CreateActionDialog.show(context);
    if (action == null || !mounted) return;

    final driveProvider = context.read<DriveProvider>();
    final auth = context.read<AuthProvider>();

    if (action == CreateAction.folder) {
      await _createFolder(driveProvider);
    } else if (action == CreateAction.upload) {
      await _uploadFile(driveProvider);
    } else if (action == CreateAction.uploadFolder) {
      await _uploadFolder(driveProvider);
    } else if (action == CreateAction.sync) {
      await _syncDocuments(auth, driveProvider);
    } else if (action == CreateAction.createSpace) {
      await _createNewSpace();
    }
  }

  Future<void> _createFolder(DriveProvider driveProvider) async {
    final folderName = await CreateFolderDialog.show(context);
    if (!mounted) return;
    if (folderName != null && folderName.isNotEmpty) {
      driveProvider.createFolder(folderName, parentId: null);
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

  Future<void> _uploadFile(DriveProvider driveProvider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await driveProvider.uploadFile(file, folderId: null);
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

  Future<void> _uploadFolder(DriveProvider driveProvider) async {
    if (!mounted) return;

    // Hiển thị loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // FilePicker không hỗ trợ chọn folder trực tiếp trên mobile
      // Nên cho phép chọn nhiều files để mô phỏng upload folder
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (!mounted) {
        Navigator.pop(context); // Đóng loading dialog
        return;
      }

      if (result != null && result.files.isNotEmpty) {
        int uploadedCount = 0;
        int failedCount = 0;

        for (final file in result.files) {
          try {
            if (file.path != null) {
              await driveProvider.uploadFile(File(file.path!), folderId: null);
              uploadedCount++;
            }
          } catch (e) {
            failedCount++;
            if (kDebugMode) {
              debugPrint('❌ Error uploading file ${file.name}: $e');
            }
          }
        }

        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog

          String message;
          if (failedCount == 0) {
            message = 'Đã tải lên $uploadedCount file(s) thành công';
          } else {
            message =
                'Đã tải lên $uploadedCount file(s), $failedCount file(s) thất bại';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor:
                  failedCount == 0 ? AppColors.primary : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thư mục: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _syncDocuments(
      AuthProvider auth, DriveProvider driveProvider) async {
    if (!mounted) return;

    // Hiển thị loading indicator với message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Không cho phép đóng bằng back button
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Đang đồng bộ dữ liệu...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (auth.isAuthenticated && auth.token != null) {
        await driveProvider.syncFromS3Api(auth.token!);
        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã đồng bộ tài liệu thành công'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Vui lòng đăng nhập để đồng bộ'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi đồng bộ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createNewSpace() async {
    if (!mounted) return;

    // Hiển thị dialog để nhập tên không gian mới
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo không gian mới'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Tên không gian',
              hintText: 'Nhập tên không gian lưu trữ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên không gian';
              }
              if (value.trim().length < 2) {
                return 'Tên không gian phải có ít nhất 2 ký tự';
              }
              return null;
            },
            onFieldSubmitted: (value) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Tạo folder mới với tên không gian
      final driveProvider = context.read<DriveProvider>();
      driveProvider.createFolder(result, parentId: null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Đã tạo không gian "$result" thành công'),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tự động load dữ liệu từ API khi token thay đổi (nếu chưa load)
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated &&
        auth.token != null &&
        _lastToken != auth.token) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDataFromApi(forceReload: true);
        }
      });
    }

    return Consumer<DriveProvider>(
      builder: (context, driveProvider, _) {
        // Hiển thị loading indicator nếu đang load
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Lấy root folders (parentId = null) và áp dụng search
        final allRootFolders = driveProvider.getFoldersByParent(null);
        final folders = allRootFolders.where((folder) {
          final query = driveProvider.searchQuery.toLowerCase();
          return query.isEmpty || folder.name.toLowerCase().contains(query);
        }).toList();

        // Lấy root files (folderId = null) và áp dụng filter/search
        final allRootFiles = driveProvider.getFilesByFolder(null);
        final files = allRootFiles.where((file) {
          final filterMatches =
              _matchesFilter(file, driveProvider.activeFilter);
          final searchMatches = file.matchesQuery(driveProvider.searchQuery);
          return filterMatches && searchMatches;
        }).toList();

        // Lấy tên không gian lưu trữ từ DriveProvider
        final storageSpaceName = driveProvider.storageSpaceName ?? 'TrungLM';

        return Scaffold(
          appBar: AppBar(
            title: Text(storageSpaceName),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _handleFloatingActionButton,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text(
              'Tạo mới',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  DriveSearchField(
                    value: driveProvider.searchQuery,
                    onChanged: driveProvider.updateSearch,
                  ),
                  const SizedBox(height: 16),
                  const FilterChipRow(),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Thư mục',
                    actionLabel: null,
                    onActionTap: null,
                    showViewToggle: folders.isNotEmpty,
                  ),
                  const SizedBox(height: 12),
                  folders.isEmpty
                      ? EmptyState(
                          icon: Icons.folder_outlined,
                          title: 'Chưa có thư mục',
                          subtitle:
                              'Tạo thư mục mới để tổ chức tài liệu của bạn',
                          actionLabel: 'Tạo thư mục',
                          onAction: () => _createFolder(driveProvider),
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
                              );
                            } else {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) => FolderTile(
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
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemCount: folders.length,
                              );
                            }
                          },
                        ),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'Tập tin',
                    actionLabel: null,
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
