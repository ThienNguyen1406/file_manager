import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/uaa_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._uaaService);

  final UaaService _uaaService;

  bool _isLoading = false;
  String? _token;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get error => _error;

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

  void logout() {
    _token = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

