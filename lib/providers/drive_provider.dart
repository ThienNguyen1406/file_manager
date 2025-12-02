import 'dart:io';

import 'package:flutter/material.dart';

import '../models/drive_file.dart';
import '../models/drive_folder.dart';
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
  DriveFilter _activeFilter = DriveFilter.all;
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.grid;
  final double _storageLimitGb = 200;
  double _usedStorageGb = 0.0;

  final List<DriveFolder> _folders = [];
  final List<DriveFile> _files = [];

  DriveFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  ViewMode get viewMode => _viewMode;
  double get storageLimitGb => _storageLimitGb;
  double get usedStorageGb => _usedStorageGb;
  List<DriveFolder> get folders => List.unmodifiable(
      _folders.where((folder) => !folder.isDeleted).toList());
  List<DriveFile> get files => List.unmodifiable(
      _files.where((file) => !file.isDeleted).toList());
  
  // Lấy folders đã xóa (trong thùng rác)
  List<DriveFolder> get trashedFolders => List.unmodifiable(
      _folders.where((folder) => folder.isDeleted).toList());
  
  // Lấy files đã xóa (trong thùng rác)
  List<DriveFile> get trashedFiles => List.unmodifiable(
      _files.where((file) => file.isDeleted).toList());
  
  // Lấy folders con của một folder (hoặc root folders nếu parentId = null)
  List<DriveFolder> getFoldersByParent(String? parentId) {
    return _folders.where((folder) => 
        folder.parentId == parentId && !folder.isDeleted).toList();
  }
  
  // Lấy files trong một folder (hoặc root files nếu folderId = null)
  List<DriveFile> getFilesByFolder(String? folderId) {
    return _files.where((file) => 
        file.folderId == folderId && !file.isDeleted).toList();
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
    
    notifyListeners();
  }
  
  // Xóa file vào thùng rác
  void deleteFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    
    _files[index].isDeleted = true;
    _files[index].deletedAt = DateTime.now();
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    
    notifyListeners();
  }
  
  // Khôi phục file từ thùng rác
  void restoreFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    
    _files[index].isDeleted = false;
    _files[index].deletedAt = null;
    notifyListeners();
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
    notifyListeners();
  }

  void updateSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    notifyListeners();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void toggleStar(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    _files[index].isStarred = !_files[index].isStarred;
    notifyListeners();
  }

  void toggleFavoriteFile(String fileId) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index == -1) return;
    _files[index].isFavorite = !_files[index].isFavorite;
    notifyListeners();
  }

  void toggleFavoriteFolder(String folderId) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index == -1) return;
    _folders[index].isFavorite = !_folders[index].isFavorite;
    notifyListeners();
  }
  
  // Lấy danh sách files yêu thích
  List<DriveFile> get favoriteFiles => _files.where((f) => 
      f.isFavorite && !f.isDeleted).toList();
  
  // Lấy danh sách folders yêu thích
  List<DriveFolder> get favoriteFolders => _folders.where((f) => 
      f.isFavorite && !f.isDeleted).toList();

  void simulateUpload(double sizeInGb) {
    _usedStorageGb = (_usedStorageGb + sizeInGb).clamp(0, _storageLimitGb);
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
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

  IconData _getFileIcon(DriveFileType type) {
    switch (type) {
      case DriveFileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case DriveFileType.doc:
        return Icons.description_outlined;
      case DriveFileType.sheet:
        return Icons.grid_on_outlined;
      case DriveFileType.slide:
        return Icons.slideshow_outlined;
      case DriveFileType.image:
        return Icons.image_outlined;
      case DriveFileType.video:
        return Icons.play_circle_outline;
    }
  }

  Color _getFileColor(DriveFileType type) {
    switch (type) {
      case DriveFileType.pdf:
        return const Color(0xFFFFE1E4);
      case DriveFileType.doc:
        return const Color(0xFFE3F2FD);
      case DriveFileType.sheet:
        return const Color(0xFFE0F2F1);
      case DriveFileType.slide:
        return const Color(0xFFFFF4E6);
      case DriveFileType.image:
        return const Color(0xFFE0F7FA);
      case DriveFileType.video:
        return const Color(0xFFEDE7F6);
    }
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

