import 'package:flutter/foundation.dart';

import '../models/account_info.dart';
import '../models/menu_view.dart';
import '../models/user_role.dart';
import '../services/uaa_service.dart';

class RemoteDataProvider extends ChangeNotifier {
  RemoteDataProvider(this._uaaService);

  final UaaService _uaaService;

  bool _isLoading = false;
  String? _error;
  List<dynamic>? _menuSwaps;
  List<MenuView>? _menuViews;
  AccountInfo? _accountInfo;
  List<UserRole>? _userRoles;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic>? get menuSwaps => _menuSwaps;
  List<MenuView>? get menuViews => _menuViews;
  AccountInfo? get accountInfo => _accountInfo;
  List<UserRole>? get userRoles => _userRoles;
  
  // Lấy các menu đã kích hoạt (dịch vụ của user)
  List<MenuView> get activatedMenus {
    if (_menuViews == null) return [];
    return _menuViews!.where((menu) => menu.isActivated).toList();
  }
  
  // Lấy các menu chưa kích hoạt
  List<MenuView> get inactiveMenus {
    if (_menuViews == null) return [];
    return _menuViews!.where((menu) => !menu.isActivated).toList();
  }
  
  // Kiểm tra có thông tin user không
  bool get hasUserInfo => _accountInfo != null || (_userRoles != null && _userRoles!.isNotEmpty);

  Future<void> loadRemoteData(String token) async {
    if (_isLoading) return;
    if (token.isEmpty) {
      _error = 'Token không hợp lệ';
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    _error = null;
    final List<String> errors = [];
    notifyListeners();
    
    try {
      // Fetch từng API riêng để có thể log lỗi cụ thể
      // MenuSwaps
      try {
        _menuSwaps = await _uaaService.fetchMenuSwaps(token);
        if (kDebugMode) {
          debugPrint('✅ MenuSwaps: ${_menuSwaps?.length ?? 0} items');
        }
      } catch (e) {
        _menuSwaps = [];
        errors.add('MenuSwaps: ${e.toString()}');
        if (kDebugMode) {
          debugPrint('❌ MenuSwaps error: $e');
        }
      }
      
      // MenuViews
      try {
        final menuViewsRaw = await _uaaService.fetchMenuViews(token);
        _menuViews = menuViewsRaw
            .whereType<Map<String, dynamic>>()
            .map((item) => MenuView.fromJson(item))
            .toList();
        if (kDebugMode) {
          debugPrint('✅ MenuViews: ${_menuViews?.length ?? 0} items');
        }
      } catch (e) {
        _menuViews = [];
        errors.add('MenuViews: ${e.toString()}');
        if (kDebugMode) {
          debugPrint('❌ MenuViews error: $e');
        }
      }
      
      // AccountInfo
      try {
        final accountInfoRaw = await _uaaService.fetchAccountInfo(token);
        if (accountInfoRaw.isNotEmpty && !accountInfoRaw.containsKey('error')) {
          _accountInfo = AccountInfo.fromJson(accountInfoRaw);
          if (kDebugMode) {
            debugPrint('✅ AccountInfo: ${_accountInfo?.fullName ?? "N/A"}');
          }
        } else {
          _accountInfo = null;
          if (kDebugMode) {
            debugPrint('⚠️ AccountInfo: empty or error');
          }
        }
      } catch (e) {
        _accountInfo = null;
        errors.add('AccountInfo: ${e.toString()}');
        if (kDebugMode) {
          debugPrint('❌ AccountInfo error: $e');
        }
      }
      
      // UserRoles
      try {
        final userRolesRaw = await _uaaService.fetchUserRoles(token);
        _userRoles = userRolesRaw
            .whereType<Map<String, dynamic>>()
            .map((item) => UserRole.fromJson(item))
            .toList();
        if (kDebugMode) {
          debugPrint('✅ UserRoles: ${_userRoles?.length ?? 0} items');
        }
      } catch (e) {
        _userRoles = [];
        errors.add('UserRoles: ${e.toString()}');
        if (kDebugMode) {
          debugPrint('❌ UserRoles error: $e');
        }
      }
      
      // Set error nếu tất cả đều fail
      if (errors.isNotEmpty && 
          (_menuViews == null || _menuViews!.isEmpty) &&
          _accountInfo == null &&
          (_userRoles == null || _userRoles!.isEmpty)) {
        _error = errors.join('; ');
      } else if (errors.isNotEmpty) {
        // Có một số data thành công, chỉ log warning
        if (kDebugMode) {
          debugPrint('⚠️ Một số API có lỗi nhưng vẫn có data: ${errors.join("; ")}');
        }
      }
      
    } catch (e) {
      _error = e.toString().replaceAll('ApiException', 'Lỗi');
      if (kDebugMode) {
        debugPrint('❌ LoadRemoteData error: $e');
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void reset() {
    _menuSwaps = null;
    _menuViews = null;
    _accountInfo = null;
    _userRoles = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

