import '../models/drive_file.dart';

class FileUtils {
  static DriveFileType getFileTypeFromExtension(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case '.pdf':
        return DriveFileType.pdf;
      case '.doc':
      case '.docx':
        return DriveFileType.doc;
      case '.xls':
      case '.xlsx':
      case '.gsheet':
        return DriveFileType.sheet;
      case '.ppt':
      case '.pptx':
      case '.ppts':
        return DriveFileType.slide;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return DriveFileType.image;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.mkv':
        return DriveFileType.video;
      default:
        return DriveFileType.doc;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return '';
    return '.${parts.last}';
  }
}

