import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/create_action_dialog.dart';
import '../../components/create_folder_dialog.dart';
import '../../components/empty_state.dart';
import '../../components/file_tile.dart';
import '../../components/filter_chip_row.dart';
import '../../components/folder_card.dart';
import '../../components/file_grid_item.dart';
import '../../components/search_field.dart';
import '../../components/section_header.dart';
import '../../constants/app_colors.dart';
import '../../models/drive_file.dart';
import '../../page/folder_detail/folder_detail_page.dart';
import '../../providers/drive_provider.dart';

class MyFilesPage extends StatefulWidget {
  const MyFilesPage({super.key});

  @override
  State<MyFilesPage> createState() => _MyFilesPageState();
}

class _MyFilesPageState extends State<MyFilesPage> {
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
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriveProvider>(
      builder: (context, driveProvider, _) {
        // Lấy root folders (parentId = null)
        final folders = driveProvider.getFoldersByParent(null);
        // Lấy root files (folderId = null) và áp dụng filter/search
        final allRootFiles = driveProvider.getFilesByFolder(null);
        final files = allRootFiles.where((file) {
          final filterMatches = _matchesFilter(file, driveProvider.activeFilter);
          final searchMatches = file.matchesQuery(driveProvider.searchQuery);
          return filterMatches && searchMatches;
        }).toList();

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
                          onAction: () => _createFolder(driveProvider),
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
                    title: 'Tập tin',
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
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
}

