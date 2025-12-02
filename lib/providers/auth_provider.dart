import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/uaa_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._uaaService, this._storageService);

  final UaaService _uaaService;
  final StorageService _storageService;

  bool _isLoading = false;
  String? _token;
  String? _error;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get error => _error;

  // Load token từ storage khi khởi động
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final savedToken = await _storageService.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        if (kDebugMode) {
          debugPrint('✅ AuthProvider: Loaded saved token');
        }
        notifyListeners();
      } else {
        if (kDebugMode) {
          debugPrint('ℹ️ AuthProvider: No saved token found');
        }
      }
    } catch (e) {
      // Ignore initialization errors, app vẫn hoạt động bình thường
      if (kDebugMode) {
        debugPrint('⚠️ AuthProvider initialize error: $e');
      }
    }
  }

  Future<void> login({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final newToken = await _uaaService.authenticate(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
      _token = newToken;
      _error = null;

      // Lưu token nếu rememberMe = true
      try {
        if (rememberMe) {
          await _storageService.saveToken(newToken);
        }
        await _storageService.saveRememberMe(rememberMe);
      } catch (e) {
        // Ignore storage errors, đăng nhập vẫn thành công
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _error = 'Tên đăng nhập hoặc mật khẩu không đúng';
      } else {
        _error = e.message;
      }
    } catch (e) {
      _error = 'Không thể đăng nhập: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('🔴 AuthProvider: Logging out...');
    }
    _token = null;
    _error = null;
    try {
      await _storageService.removeToken();
      if (kDebugMode) {
        debugPrint('✅ AuthProvider: Token removed from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AuthProvider: Error removing token: $e');
      }
    }
    notifyListeners();
    if (kDebugMode) {
      debugPrint('✅ AuthProvider: Logout complete, isAuthenticated: $isAuthenticated');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
