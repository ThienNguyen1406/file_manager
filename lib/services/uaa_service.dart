import 'dart:convert';

import 'api_client.dart';
import '../constants/api_endpoints.dart';

class UaaService {
  UaaService(this._client);

  final ApiClient _client;

  Future<String> authenticate({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    // Thử các endpoint theo thứ tự ưu tiên

    // 1. Thử endpoint login chính với email
    try {
      final response = await _client.post(
        ApiEndpoints.loginAuth,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': username, // Có thể là email
          'password': password,
          'rememberMe': rememberMe,
        }),
      );
      return _extractToken(response.body);
    } on ApiException catch (e1) {
      // Nếu không phải lỗi 401/403, thử endpoint khác
      if (e1.statusCode != 401 && e1.statusCode != 403) {
        // 2. Thử endpoint customer-logins/email
        try {
          final response = await _client.post(
            ApiEndpoints.loginEmail,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': username,
              'password': password,
            }),
          );
          return _extractToken(response.body);
        } on ApiException catch (e2) {
          // 3. Thử với username thay vì email
          try {
            final response = await _client.post(
              ApiEndpoints.loginAuth,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': username,
                'password': password,
                'rememberMe': rememberMe,
              }),
            );
            return _extractToken(response.body);
          } on ApiException catch (e3) {
            // 4. Thử endpoint cũ (fallback)
            try {
              final response = await _client.post(
                ApiEndpoints.authenticate,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'username': username,
                  'password': password,
                  'rememberMe': rememberMe,
                }),
              );
              return _extractToken(response.body);
            } on ApiException {
              // Nếu tất cả đều thất bại, throw lỗi 401/403 đầu tiên hoặc lỗi đầu tiên
              if (e1.statusCode == 401 || e1.statusCode == 403) {
                throw e1;
              }
              if (e2.statusCode == 401 || e2.statusCode == 403) {
                throw e2;
              }
              if (e3.statusCode == 401 || e3.statusCode == 403) {
                throw e3;
              }
              throw e1; // Throw lỗi đầu tiên
            }
          }
        }
      }
      rethrow; // Nếu là 401/403, throw ngay
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lỗi khi xử lý đăng nhập: $e');
    }
  }

  String _extractToken(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      // Hỗ trợ nhiều format response
      String? token;
      if (decoded is Map<String, dynamic>) {
        token = decoded['id_token'] as String? ??
            decoded['token'] as String? ??
            decoded['access_token'] as String? ??
            decoded['jwt'] as String?;
      }

      if (token == null || token.isEmpty) {
        throw ApiException(
          'Không tìm thấy token trong response. Response: $responseBody',
        );
      }
      return token;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lỗi khi parse response: $e');
    }
  }

  Future<List<dynamic>> fetchMenuSwaps(String token) async {
    final response =
        await _client.get(ApiEndpoints.menuSwaps, headers: _headers(token));
    return _decodeList(response.body);
  }

  Future<List<dynamic>> fetchMenuViews(String token) async {
    final response =
        await _client.get(ApiEndpoints.menuViews, headers: _headers(token));
    return _decodeList(response.body);
  }

  Future<Map<String, dynamic>> fetchAccountInfo(String token) async {
    final response =
        await _client.get(ApiEndpoints.accountInfo, headers: _headers(token));
    return _decodeMap(response.body);
  }

  Future<List<dynamic>> fetchUserRoles(String token) async {
    final response = await _client.get(
      ApiEndpoints.userRoleSearch,
      headers: _headers(token),
    );
    final body = jsonDecode(response.body);
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final content = body['content'];
      if (content is List) return content;
    }
    return [];
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  List<dynamic> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final embedded = decoded['data'];
      if (embedded is List) return embedded;
    }
    return [];
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'raw': decoded};
  }
}
