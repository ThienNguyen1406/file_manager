import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/drive_file.dart';
import '../models/drive_folder.dart';
import '../services/api_client.dart';
import '../services/s3_service.dart';
import '../services/storage_service.dart';
import '../util/file_utils.dart';

enum DriveFilter { all, docs, sheets, slides, media, shared }

enum ViewMode { grid, list }

extension DriveFilterLabel on DriveFilter {
  String get label {
    switch (this) {
      case DriveFilter.docs:
        return 'Tài liệu';
      case DriveFilter.sheets:
        return 'Trang tính';
      case DriveFilter.slides:
        return 'Trình chiếu';
      case DriveFilter.media:
        return 'Hình ảnh & video';
      case DriveFilter.shared:
        return 'Chia sẻ';
      case DriveFilter.all:
        return 'Tất cả';
    }
  }

  IconData get icon {
    switch (this) {
      case DriveFilter.docs:
        return Icons.description_outlined;
      case DriveFilter.sheets:
        return Icons.grid_view_outlined;
      case DriveFilter.slides:
        return Icons.slideshow_outlined;
      case DriveFilter.media:
        return Icons.image_outlined;
      case DriveFilter.shared:
        return Icons.people_alt_outlined;
      case DriveFilter.all:
        return Icons.folder_open;
    }
  }
}

class DriveProvider extends ChangeNotifier {
  DriveProvider(this._storageService) {
    // Khởi tạo S3Service để sync từ API
    _apiClient = ApiClient();
    _s3Service = S3Service(_apiClient);
  }

  final StorageService _storageService;
  late final ApiClient _apiClient;
  late final S3Service _s3Service;

  DriveFilter _activeFilter = DriveFilter.all;
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.grid;
  final double _storageLimitGb = 200;
  double _usedStorageGb = 0.0;
  String? _storageSpaceName; // Tên không gian lưu trữ từ S3 API

  final List<DriveFolder> _folders = [];
  final List<DriveFile> _files = [];
  bool _isInitialized = false;

  // Load dữ liệu từ storage khi khởi động
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Load folders và files
      final savedFolders = await _storageService.getFolders();
      final savedFiles = await _storageService.getFiles();
      final savedStorage = await _storageService.getUsedStorage();
      final savedViewMode = await _storageService.getViewMode();

      _folders.clear();
      _folders.addAll(savedFolders);

      _files.clear();
      _files.addAll(savedFiles);

      _usedStorageGb = savedStorage;

      if (savedViewMode != null) {
        _viewMode = savedViewMode == 'list' ? ViewMode.list : ViewMode.grid;
      }

      if (kDebugMode) {
        debugPrint('✅ DriveProvider initialized:');
        debugPrint('   - Folders: ${_folders.length}');
        debugPrint('   - Files: ${_files.length}');
        debugPrint('   - Used Storage: $_usedStorageGb GB');
        debugPrint('   - View Mode: ${_viewMode.name}');
      }

      notifyListeners();
    } catch (e) {
      // Ignore initialization errors, app vẫn hoạt động bình thường
      // Dữ liệu sẽ bắt đầu từ trống
      // Debug: log error để kiểm tra
      debugPrint('⚠️ DriveProvider initialize error: $e');
    }
  }

  // Lưu dữ liệu vào storage
  Future<void> _saveData() async {
    await Future.wait([
      _storageService.saveFolders(_folders),
      _storageService.saveFiles(_files),
      _storageService.saveUsedStorage(_usedStorageGb),
      _storageService.saveViewMode(_viewMode.name),
    ]);
  }

  // Helper để notify và save
  void _notifyAndSave() {
    notifyListeners();
    _saveData(); // Lưu bất đồng bộ, không cần await
  }

  // Sync dữ liệu từ S3 API
  Future<void> syncFromS3Api(String token) async {
    if (kDebugMode) {
      debugPrint('🔄 DriveProvider: Syncing from S3 API...');
      debugPrint(
          '   Current folders: ${_folders.length}, files: ${_files.length}');
    }

    try {
      // Clear dữ liệu cũ của root folder trước khi sync mới
      // Chỉ xóa các items có parentId = null (root items)
      _folders.removeWhere((folder) => folder.parentId == null);
      _files.removeWhere((file) => file.folderId == null);

      if (kDebugMode) {
        debugPrint('   Cleared old root items');
      }
      // Lấy resource details của root folder (TrungLM)
      try {
        final resourceDetails = await _s3Service.fetchResourceDetails(
          token: token,
          resourceId: 'a5d154f3-518e-423f-8cef-8694875e60c4',
        );

        if (resourceDetails.containsKey('data')) {
          final data = resourceDetails['data'] as Map<String, dynamic>;
          final resourceId = data['resource_id'] as String? ?? '';
          final resourceName = data['resource_name'] as String? ?? 'TrungLM';
          final resourceType = data['resource_type'] as String? ?? 'folder';
          final parentId = data['resource_parent_id'] as String?;
          final isRoot = parentId == '00000000-0000-0000-0000-000000000000' ||
              parentId == null;

          // Lưu tên không gian lưu trữ từ S3 API (luôn lấy từ API)
          _storageSpaceName =
              resourceName.isNotEmpty ? resourceName : 'TrungLM';

          if (kDebugMode) {
            debugPrint(
                '✅ Resource Details: $resourceName (type: $resourceType)');
            debugPrint('   Storage space name saved: $_storageSpaceName');
          }

          // Notify để app_drawer có thể cập nhật
          notifyListeners();

          // Nếu là root folder, lấy children từ API
          // Thử dùng fetchResources với parentId trước, nếu không được thì dùng resourceTab
          if (isRoot && resourceType == 'folder') {
            try {
              // Thử dùng fetchResources với parentId để lấy children trực tiếp
              final resources = await _s3Service.fetchResources(
                token: token,
                pageOffset: 1,
                pageSize: 1000,
                parentId: resourceId,
              );

              if (kDebugMode) {
                debugPrint(
                    '✅ Fetch Resources with parentId: ${resources.keys}');
              }

              // Nếu có dữ liệu từ fetchResources, dùng nó
              if (resources.containsKey('data') && resources['data'] is List) {
                final dataList = resources['data'] as List;
                if (dataList.isNotEmpty) {
                  if (kDebugMode) {
                    debugPrint(
                        '✅ Using fetchResources data: ${dataList.length} items');
                  }
                  _parseAndSyncResourceList(dataList, resourceId);
                  return; // Thành công, không cần dùng resourceTab
                }
              }

              // Nếu fetchResources không trả về dữ liệu, thử resourceTab
              if (kDebugMode) {
                debugPrint(
                    '⚠️ fetchResources returned empty, trying resourceTab...');
              }

              final resourceTab = await _s3Service.fetchResourceTab(
                token: token,
                pageOffset: 1,
                pageSize: 1000,
              );

              if (kDebugMode) {
                debugPrint('✅ Resource Tab: ${resourceTab.keys}');
                if (resourceTab.containsKey('data') &&
                    resourceTab['data'] is Map) {
                  final dataMap = resourceTab['data'] as Map<String, dynamic>;
                  debugPrint('   data keys: ${dataMap.keys}');
                  if (dataMap.containsKey('data') && dataMap['data'] is List) {
                    debugPrint(
                        '   data.data length: ${(dataMap['data'] as List).length}');
                  }
                }
              }

              // Parse và sync dữ liệu từ resource tab
              // Chỉ lấy items có parent_id = resourceId (children của folder này)
              _parseAndSyncResourceTab(resourceTab, resourceId);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Error fetching resources: $e');
              }
            }
          }
        } else {
          // Nếu không có data từ resource details, set default name
          if (_storageSpaceName == null || _storageSpaceName!.isEmpty) {
            _storageSpaceName = 'TrungLM';
            notifyListeners();
          }
          if (kDebugMode) {
            debugPrint(
                '⚠️ Resource Details: No data found, using default name');
          }
        }
      } catch (e) {
        // Nếu lỗi khi fetch resource details, vẫn set default name
        if (_storageSpaceName == null || _storageSpaceName!.isEmpty) {
          _storageSpaceName = 'TrungLM';
          notifyListeners();
        }
        if (kDebugMode) {
          debugPrint('⚠️ Error fetching resource details: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error syncing from S3 API: $e');
      }
    }
  }

  // Parse và sync từ List trực tiếp (từ fetchResources)
  void _parseAndSyncResourceList(
      List<dynamic> resourceList, String parentFolderId) {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Parsing resource list: ${resourceList.length} items');
      }

      final List<DriveFolder> newFolders = [];
      final List<DriveFile> newFiles = [];

      for (final item in resourceList) {
        try {
          if (item is! Map<String, dynamic>) {
            if (kDebugMode) {
              debugPrint('⚠️ Skipping non-map item: ${item.runtimeType}');
            }
            continue;
          }

          final resourceType = item['resource_type'] as String? ?? '';
          final resourceId = item['resource_id'] as String?;
          final resourceName = item['resource_name'] as String?;

          // Validate required fields
          if (resourceId == null || resourceId.isEmpty) {
            continue;
          }

          if (resourceName == null || resourceName.isEmpty) {
            continue;
          }

          final size = (item['size'] as num?)?.toDouble() ?? 0.0;
          final isFolder =
              item['resource_folder'] as bool? ?? (resourceType == 'folder');
          final isFavorite = item['resource_favorite'] as bool? ?? false;
          final createdAt = item['created_at'] as String? ?? '';
          final modifiedAt = item['modify_at'] as String? ??
              item['last_opened_date'] as String? ??
              createdAt;
          final createdBy = item['created_by'] as String? ?? 'Bạn';

          if (isFolder) {
            try {
              final folder = DriveFolder(
                id: resourceId,
                name: resourceName,
                fileCount:
                    (item['resource_children_size'] as num?)?.toInt() ?? 0,
                storageUsedGb: size / (1024 * 1024 * 1024),
                color: AppColors.primary,
                icon: Icons.folder,
                parentId:
                    parentFolderId == 'a5d154f3-518e-423f-8cef-8694875e60c4'
                        ? null
                        : parentFolderId,
                isFavorite: isFavorite,
              );
              newFolders.add(folder);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ Error creating DriveFolder for $resourceId: $e');
              }
            }
          } else {
            try {
              final fileType = _getFileTypeFromName(resourceName);
              final file = DriveFile(
                id: resourceId,
                name: resourceName,
                owner: createdBy.isNotEmpty ? createdBy : 'Bạn',
                updatedAt: modifiedAt.isNotEmpty ? modifiedAt : createdAt,
                sizeLabel: _formatFileSize(size),
                type: fileType,
                icon: _getFileIcon(fileType),
                color: _getFileColor(fileType),
                isStarred: false,
                isFavorite: isFavorite,
                folderId:
                    parentFolderId == 'a5d154f3-518e-423f-8cef-8694875e60c4'
                        ? null
                        : parentFolderId,
              );
              newFiles.add(file);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ Error creating DriveFile for $resourceId: $e');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error processing item: $e');
          }
          continue;
        }
      }

      // Merge với dữ liệu hiện tại
      for (final folder in newFolders) {
        try {
          final existingIndex = _folders.indexWhere((f) => f.id == folder.id);
          if (existingIndex >= 0) {
            _folders[existingIndex] = folder;
          } else {
            _folders.add(folder);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error merging folder ${folder.id}: $e');
          }
        }
      }

      for (final file in newFiles) {
        try {
          final existingIndex = _files.indexWhere((f) => f.id == file.id);
          if (existingIndex >= 0) {
            _files[existingIndex] = file;
          } else {
            _files.add(file);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error merging file ${file.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
            '✅ Synced from list: ${newFolders.length} folders, ${newFiles.length} files');
      }

      _notifyAndSave();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing resource list: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  void _parseAndSyncResourceTab(
      Map<String, dynamic> resourceTab, String parentFolderId) {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Parsing resource tab: ${resourceTab.keys}');
      }

      // Tìm data trong response
      // Cấu trúc có thể là: {"data": {"data": [...]}} hoặc {"data": [...]}
      dynamic data;

      if (resourceTab.containsKey('data')) {
        final dataValue = resourceTab['data'];
        // Nếu data là Map và có key 'data' bên trong (nested structure)
        if (dataValue is Map<String, dynamic> &&
            dataValue.containsKey('data')) {
          data = dataValue['data'];
          if (kDebugMode) {
            debugPrint('✅ Found nested data structure: data.data');
            if (data is List) {
              debugPrint('   Items count: ${data.length}');
            }
          }
        } else if (dataValue is List) {
          // Nếu data là List trực tiếp
          data = dataValue;
          if (kDebugMode) {
            debugPrint('✅ Found direct data list');
            debugPrint('   Items count: ${data.length}');
          }
        } else {
          data = dataValue;
        }
      } else if (resourceTab.containsKey('content')) {
        data = resourceTab['content'];
      } else if (resourceTab.containsKey('items')) {
        data = resourceTab['items'];
      } else {
        // Thử tìm List trong values
        for (final value in resourceTab.values) {
          if (value is List) {
            data = value;
            break;
          }
          // Nếu value là Map, thử tìm 'data' bên trong
          if (value is Map<String, dynamic> && value.containsKey('data')) {
            final nestedData = value['data'];
            if (nestedData is List) {
              data = nestedData;
              break;
            }
          }
        }
      }

      if (data == null || data is! List) {
        if (kDebugMode) {
          debugPrint('⚠️ Resource Tab data is not a List: ${data.runtimeType}');
          debugPrint('   Available keys: ${resourceTab.keys}');
          if (resourceTab.containsKey('data')) {
            final dataValue = resourceTab['data'];
            debugPrint('   data type: ${dataValue.runtimeType}');
            if (dataValue is Map<String, dynamic>) {
              debugPrint('   data keys: ${dataValue.keys}');
            }
          }
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ Found ${data.length} items in resource tab');
        debugPrint('   Looking for items with parent_id = $parentFolderId');
        // Log một vài items đầu tiên để debug
        if (data.isNotEmpty && data.first is Map) {
          final firstItem = data.first as Map<String, dynamic>;
          debugPrint(
              '   Sample item parent_id: ${firstItem['resource_parent_id']}');
        }
      }

      final List<DriveFolder> newFolders = [];
      final List<DriveFile> newFiles = [];
      int skippedCount = 0;
      int includedCount = 0;

      for (final item in data) {
        try {
          if (item is! Map<String, dynamic>) {
            if (kDebugMode) {
              debugPrint('⚠️ Skipping non-map item: ${item.runtimeType}');
            }
            continue;
          }

          final resourceType = item['resource_type'] as String? ?? '';
          final resourceId = item['resource_id'] as String?;
          final resourceName = item['resource_name'] as String?;
          final resourceParentId = item['resource_parent_id'] as String?;

          // Validate required fields
          if (resourceId == null || resourceId.isEmpty) {
            if (kDebugMode) {
              debugPrint('⚠️ Skipping item with empty resource_id');
            }
            continue;
          }

          if (resourceName == null || resourceName.isEmpty) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Skipping item with empty resource_name: $resourceId');
            }
            continue;
          }

          // Chỉ lấy items có parent_id = parentFolderId (children của folder hiện tại)
          // Nếu parent_id không khớp, bỏ qua item này (không phải child của folder hiện tại)
          if (resourceParentId != parentFolderId) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 5) {
              // Chỉ log 5 items đầu tiên để tránh spam
              debugPrint(
                  '⚠️ Skipping item: parent_id mismatch. Expected: $parentFolderId, Got: $resourceParentId (name: $resourceName)');
            }
            continue;
          }

          includedCount++;
          if (kDebugMode && includedCount <= 10) {
            // Chỉ log 10 items đầu tiên để tránh spam
            debugPrint(
                '✅ Including item: $resourceName (type: $resourceType, parent: $resourceParentId)');
          }

          final size = (item['size'] as num?)?.toDouble() ?? 0.0;
          final isFolder =
              item['resource_folder'] as bool? ?? (resourceType == 'folder');
          final isFavorite = item['resource_favorite'] as bool? ?? false;
          final createdAt = item['created_at'] as String? ?? '';
          final modifiedAt = item['modify_at'] as String? ??
              item['last_opened_date'] as String? ??
              createdAt;
          final createdBy = item['created_by'] as String? ?? 'Bạn';

          if (isFolder) {
            // Tạo DriveFolder
            try {
              final folder = DriveFolder(
                id: resourceId,
                name: resourceName,
                fileCount:
                    (item['resource_children_size'] as num?)?.toInt() ?? 0,
                storageUsedGb:
                    size / (1024 * 1024 * 1024), // Convert bytes to GB
                color: AppColors.primary,
                icon: Icons.folder,
                parentId:
                    parentFolderId == 'a5d154f3-518e-423f-8cef-8694875e60c4'
                        ? null
                        : parentFolderId,
                isFavorite: isFavorite,
              );
              newFolders.add(folder);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ Error creating DriveFolder for $resourceId: $e');
              }
            }
          } else {
            // Tạo DriveFile
            try {
              final fileType = _getFileTypeFromName(resourceName);
              final file = DriveFile(
                id: resourceId,
                name: resourceName,
                owner: createdBy.isNotEmpty ? createdBy : 'Bạn',
                updatedAt: modifiedAt.isNotEmpty ? modifiedAt : createdAt,
                sizeLabel: _formatFileSize(size),
                type: fileType,
                icon: _getFileIcon(fileType),
                color: _getFileColor(fileType),
                isStarred: false,
                isFavorite: isFavorite,
                folderId:
                    parentFolderId == 'a5d154f3-518e-423f-8cef-8694875e60c4'
                        ? null
                        : parentFolderId,
              );
              newFiles.add(file);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ Error creating DriveFile for $resourceId: $e');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error processing item: $e');
          }
          // Continue với item tiếp theo
          continue;
        }
      }

      // Merge với dữ liệu hiện tại (không xóa dữ liệu local)
      for (final folder in newFolders) {
        final existingIndex = _folders.indexWhere((f) => f.id == folder.id);
        if (existingIndex >= 0) {
          _folders[existingIndex] = folder;
        } else {
          _folders.add(folder);
        }
      }

      for (final file in newFiles) {
        final existingIndex = _files.indexWhere((f) => f.id == file.id);
        if (existingIndex >= 0) {
          _files[existingIndex] = file;
        } else {
          _files.add(file);
        }
      }

      if (kDebugMode) {
        debugPrint(
            '✅ Synced from Resource Tab: ${newFolders.length} folders, ${newFiles.length} files');
        debugPrint('   Total items processed: ${data.length}');
        debugPrint('   Included: $includedCount items');
        debugPrint('   Skipped: $skippedCount items (wrong parent_id)');
      }

      _notifyAndSave();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing resource tab: $e');
      }
    }
  }

  DriveFileType _getFileTypeFromName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return DriveFileType.pdf;
      case 'xlsx':
      case 'xls':
        return DriveFileType.sheet;
      case 'pptx':
      case 'ppt':
        return DriveFileType.slide;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return DriveFileType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return DriveFileType.video;
      default:
        return DriveFileType.doc;
    }
  }

  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getFileIcon(DriveFileType type) {
    switch (type) {
      case DriveFileType.doc:
        return Icons.description;
      case DriveFileType.sheet:
        return Icons.grid_on;
      case DriveFileType.slide:
        return Icons.slideshow;
      case DriveFileType.pdf:
        return Icons.picture_as_pdf;
      case DriveFileType.image:
        return Icons.image;
      case DriveFileType.video:
        return Icons.video_library;
    }
  }

  Color _getFileColor(DriveFileType type) {
    switch (type) {
      case DriveFileType.doc:
        return const Color(0xFFE3F2FD);
      case DriveFileType.sheet:
        return const Color(0xFFE0F2F1);
      case DriveFileType.slide:
        return const Color(0xFFFFF4E6);
      case DriveFileType.pdf:
        return const Color(0xFFFCE4EC);
      case DriveFileType.image:
        return const Color(0xFFE0F7FA);
      case DriveFileType.video:
        return const Color(0xFFEDE7F6);
    }
  }

  // Clear tất cả dữ liệu (dùng khi logout)
  Future<void> clearAllData() async {
    _folders.clear();
    _files.clear();
    _usedStorageGb = 0.0;
    _searchQuery = '';
    _activeFilter = DriveFilter.all;
    _viewMode = ViewMode.grid;
    _storageSpaceName = null; // Reset tên không gian lưu trữ

    // Xóa dữ liệu trong storage
    try {
      await _storageService.clearAll();
    } catch (e) {
      // Ignore errors
    }

    notifyListeners();
  }

  DriveFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  ViewMode get viewMode => _viewMode;
  double get storageLimitGb => _storageLimitGb;
  double get usedStorageGb => _usedStorageGb;
  String? get storageSpaceName =>
      _storageSpaceName; // Tên không gian lưu trữ từ S3 API
  List<DriveFolder> get folders =>
      List.unmodifiable(_folders.where((folder) => !folder.isDeleted).toList());
  List<DriveFile> get files =>
      List.unmodifiable(_files.where((file) => !file.isDeleted).toList());

  // Lấy folders đã xóa (trong thùng rác)
  List<DriveFolder> get trashedFolders =>
      List.unmodifiable(_folders.where((folder) => folder.isDeleted).toList());

  // Lấy files đã xóa (trong thùng rác)
  List<DriveFile> get trashedFiles =>
      List.unmodifiable(_files.where((file) => file.isDeleted).toList());

  // Lấy folders con của một folder (hoặc root folders nếu parentId = null)
  List<DriveFolder> getFoldersByParent(String? parentId) {
    return _folders
        .where((folder) => folder.parentId == parentId && !folder.isDeleted)
        .toList();
  }

  // Lấy files trong một folder (hoặc root files nếu folderId = null)
  List<DriveFile> getFilesByFolder(String? folderId) {
    return _files
        .where((file) => file.folderId == folderId && !file.isDeleted)
        .toList();
  }

  // Lấy folder theo ID (bao gồm cả đã xóa)
  DriveFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((folder) => folder.id == id);
    } catch (_) {
      return null;
    }
  }

  // Lấy file theo ID (bao gồm cả đã xóa)
  DriveFile? getFileById(String id) {
    try {
      return _files.firstWhere((file) => file.id == id);
    } catch (_) {
      return null;
    }
  }

  // Xóa folder vào thùng rác
  void deleteFolder(String folderId) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index == -1) return;

    // Đánh dấu folder là đã xóa
    _folders[index].isDeleted = true;
    _folders[index].deletedAt = DateTime.now();

    // Xóa tất cả folders con vào thùng rác
    final childFolders = _folders.where((f) => f.parentId == folderId).toList();
    for (final childFolder in childFolders) {
      deleteFolder(childFolder.id);
    }

    // Xóa tất cả files trong folder vào thùng rác
    final folderFiles = _files.where((f) => f.folderId == folderId).toList();
    for (final file in folderFiles) {
      deleteFile(file.id);
    }

    _notifyAndSave();
  }

  // Xóa file vào thùng rác
  void deleteFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;

    _files[index].isDeleted = true;
    _files[index].deletedAt = DateTime.now();
    _notifyAndSave();
  }

  // Xóa vĩnh viễn folder
  void permanentDeleteFolder(String folderId) {
    // Xóa vĩnh viễn tất cả folders con trước
    final childFolders = _folders.where((f) => f.parentId == folderId).toList();
    for (final childFolder in childFolders) {
      permanentDeleteFolder(childFolder.id);
    }

    // Xóa vĩnh viễn tất cả files trong folder
    final folderFiles = _files.where((f) => f.folderId == folderId).toList();
    for (final file in folderFiles) {
      permanentDeleteFile(file.id);
    }

    // Xóa folder
    _folders.removeWhere((f) => f.id == folderId);
    _notifyAndSave();
  }

  // Xóa vĩnh viễn file
  void permanentDeleteFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;

    // Giảm storage nếu file chưa bị xóa (đã tính vào storage)
    if (!_files[index].isDeleted) {
      // Tính toán size từ sizeLabel (cần parse lại)
      // Tạm thời bỏ qua vì không có size thực tế
    }

    _files.removeAt(index);
    _notifyAndSave();
  }

  // Khôi phục folder từ thùng rác
  void restoreFolder(String folderId) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index == -1) return;

    _folders[index].isDeleted = false;
    _folders[index].deletedAt = null;

    // Khôi phục tất cả folders con
    final childFolders = _folders.where((f) => f.parentId == folderId).toList();
    for (final childFolder in childFolders) {
      restoreFolder(childFolder.id);
    }

    // Khôi phục tất cả files trong folder
    final folderFiles = _files.where((f) => f.folderId == folderId).toList();
    for (final file in folderFiles) {
      restoreFile(file.id);
    }

    _notifyAndSave();
  }

  // Khôi phục file từ thùng rác
  void restoreFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;

    _files[index].isDeleted = false;
    _files[index].deletedAt = null;
    _notifyAndSave();
  }

  double get usagePercent {
    if (_storageLimitGb == 0) return 0.0;
    return _usedStorageGb / _storageLimitGb;
  }

  List<DriveFile> get visibleFiles => _files.where((file) {
        if (file.isDeleted) return false;
        final filterMatches = _matchesFilter(file);
        final searchMatches = file.matchesQuery(_searchQuery);
        return filterMatches && searchMatches;
      }).toList();

  void selectFilter(DriveFilter filter) {
    _activeFilter = filter;
    _notifyAndSave();
  }

  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    _notifyAndSave();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    _notifyAndSave();
  }

  void toggleStar(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    _files[index].isStarred = !_files[index].isStarred;
    _notifyAndSave();
  }

  void toggleFavoriteFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    _files[index].isFavorite = !_files[index].isFavorite;
    _notifyAndSave();
  }

  void toggleFavoriteFolder(String folderId) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index == -1) return;
    _folders[index].isFavorite = !_folders[index].isFavorite;
    notifyListeners();
  }

  // Lấy danh sách files yêu thích
  List<DriveFile> get favoriteFiles =>
      _files.where((f) => f.isFavorite && !f.isDeleted).toList();

  // Lấy danh sách folders yêu thích
  List<DriveFolder> get favoriteFolders =>
      _folders.where((f) => f.isFavorite && !f.isDeleted).toList();

  void simulateUpload(double sizeInGb) {
    _usedStorageGb = (_usedStorageGb + sizeInGb).clamp(0, _storageLimitGb);
    _notifyAndSave();
  }

  void createFolder(String folderName, {String? parentId}) {
    if (folderName.trim().isEmpty) return;
    final newFolder = DriveFolder(
      id: 'fld-${DateTime.now().millisecondsSinceEpoch}',
      name: folderName.trim(),
      fileCount: 0,
      storageUsedGb: 0,
      color: _getRandomFolderColor(),
      icon: Icons.folder_outlined,
      parentId: parentId,
    );
    _folders.insert(0, newFolder);
    _notifyAndSave();
  }

  // Lấy đường dẫn folder (breadcrumb)
  List<DriveFolder> getFolderPath(String folderId) {
    final path = <DriveFolder>[];
    var currentId = folderId;

    while (currentId.isNotEmpty) {
      final folder = getFolderById(currentId);
      if (folder == null) break;
      path.insert(0, folder);
      currentId = folder.parentId ?? '';
    }

    return path;
  }

  Future<void> uploadFile(File file, {String? folderId}) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final sizeInGb = fileSize / (1024 * 1024 * 1024);
      final extension = FileUtils.getFileExtension(fileName);
      final fileType = FileUtils.getFileTypeFromExtension(extension);

      final newFile = DriveFile(
        id: 'fle-${DateTime.now().millisecondsSinceEpoch}',
        name: fileName,
        owner: 'Bạn',
        updatedAt: 'Vừa xong',
        sizeLabel: FileUtils.formatFileSize(fileSize),
        type: fileType,
        icon: _getFileIcon(fileType),
        color: _getFileColor(fileType),
        folderId: folderId,
      );

      _files.insert(0, newFile);
      _usedStorageGb = (_usedStorageGb + sizeInGb).clamp(0, _storageLimitGb);
      _notifyAndSave();
    } catch (e) {
      rethrow;
    }
  }

  Color _getRandomFolderColor() {
    final colors = [
      const Color(0xFFD7F8E4),
      const Color(0xFFE3F2FD),
      const Color(0xFFFFF3E0),
      const Color(0xFFE0F7FA),
      const Color(0xFFEDE7F6),
      const Color(0xFFFFE1E4),
    ];
    return colors[_folders.length % colors.length];
  }

  bool _matchesFilter(DriveFile file) {
    switch (_activeFilter) {
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
