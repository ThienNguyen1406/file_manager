import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/create_action_dialog.dart';
import '../../components/create_folder_dialog.dart';
import '../../components/empty_state.dart';
import '../../components/file_grid_item.dart';
import '../../components/file_tile.dart';
import '../../components/folder_card.dart';
import '../../components/section_header.dart';
import '../../constants/app_colors.dart';
import '../../models/drive_folder.dart';
import '../../providers/drive_provider.dart';

class FolderDetailPage extends StatefulWidget {
  const FolderDetailPage({
    super.key,
    required this.folder,
  });

  final DriveFolder folder;

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  String? _currentFolderId;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.folder.id;
  }

  void _navigateToFolder(String folderId) {
    setState(() {
      _currentFolderId = folderId;
    });
  }

  void _navigateUp() {
    final driveProvider = context.read<DriveProvider>();
    final currentFolder = driveProvider.getFolderById(_currentFolderId ?? '');
    if (currentFolder != null && currentFolder.parentId != null) {
      setState(() {
        _currentFolderId = currentFolder.parentId;
      });
    }
  }

  Future<void> _handleFloatingActionButton() async {
    final action = await CreateActionDialog.show(context);
    if (action == null || !mounted) return;

    final driveProvider = context.read<DriveProvider>();

    if (action == CreateAction.folder) {
      final folderName = await CreateFolderDialog.show(context);
      if (folderName != null && folderName.isNotEmpty && mounted) {
        driveProvider.createFolder(folderName, parentId: _currentFolderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo thư mục "$folderName"'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } else if (action == CreateAction.upload) {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null && mounted) {
          final file = File(result.files.single.path!);
          await driveProvider.uploadFile(file, folderId: _currentFolderId);
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
  }

  @override
  Widget build(BuildContext context) {
    final driveProvider = context.watch<DriveProvider>();
    final currentFolder = driveProvider.getFolderById(_currentFolderId ?? '');
    final folders = driveProvider.getFoldersByParent(_currentFolderId);
    final files = driveProvider.getFilesByFolder(_currentFolderId);
    final folderPath = currentFolder != null
        ? driveProvider.getFolderPath(_currentFolderId!)
        : <DriveFolder>[];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentFolder != null)
              Text(
                currentFolder.name,
                style: const TextStyle(fontSize: 18),
              )
            else
              const Text('Drive'),
            if (folderPath.isNotEmpty)
              Text(
                folderPath.map((f) => f.name).join(' / '),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (currentFolder != null && currentFolder.parentId != null) {
              _navigateUp();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
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
              if (folders.isNotEmpty) ...[
                SectionHeader(
                  title: 'Thư mục',
                  actionLabel: null,
                  onActionTap: null,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _navigateToFolder(folders[index].id),
                    child: FolderCard(folder: folders[index]),
                  ),
                  itemCount: folders.length,
                ),
                const SizedBox(height: 28),
              ],
              SectionHeader(
                title: 'Tệp tin',
                actionLabel: null, // Tạm thời ẩn "Sắp xếp" để nút toggle rõ hơn
                onActionTap: null,
                showViewToggle: files.isNotEmpty,
              ),
              const SizedBox(height: 12),
              files.isEmpty && folders.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_outlined,
                      title: 'Thư mục trống',
                      subtitle: 'Tạo thư mục hoặc tải file lên để bắt đầu',
                      actionLabel: 'Tạo mới',
                      onAction: _handleFloatingActionButton,
                    )
                  : files.isEmpty
                      ? const SizedBox.shrink()
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
  }
}

