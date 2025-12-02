import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/drive_file.dart';
import '../models/drive_folder.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyFolders = 'drive_folders';
  static const String _keyFiles = 'drive_files';
  static const String _keyUsedStorage = 'used_storage_gb';
  static const String _keyViewMode = 'view_mode';

  // Token
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } catch (e) {
      // Ignore storage errors, app vẫn hoạt động bình thường
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
    } catch (e) {
      // Ignore storage errors
    }
  }

  // Remember Me
  Future<void> saveRememberMe(bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, rememberMe);
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? true;
    } catch (e) {
      return true;
    }
  }

  // Folders
  Future<void> saveFolders(List<DriveFolder> folders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = folders.map((folder) => folder.toJson()).toList();
      await prefs.setString(_keyFolders, jsonEncode(jsonList));
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<List<DriveFolder>> getFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFolders);
      if (jsonString == null) return [];
      try {
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList
            .map((json) => DriveFolder.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Files
  Future<void> saveFiles(List<DriveFile> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = files.map((file) => file.toJson()).toList();
      await prefs.setString(_keyFiles, jsonEncode(jsonList));
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<List<DriveFile>> getFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFiles);
      if (jsonString == null) return [];
      try {
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList
            .map((json) => DriveFile.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Used Storage
  Future<void> saveUsedStorage(double usedStorageGb) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyUsedStorage, usedStorageGb);
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<double> getUsedStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyUsedStorage) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // View Mode
  Future<void> saveViewMode(String viewMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyViewMode, viewMode);
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<String?> getViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyViewMode);
    } catch (e) {
      return null;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyFolders);
      await prefs.remove(_keyFiles);
      await prefs.remove(_keyUsedStorage);
      await prefs.remove(_keyViewMode);
    } catch (e) {
      // Ignore storage errors
    }
  }
}
