import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.post(uri, headers: headers, body: body);
    return _handle(response);
  }

  Future<http.Response> postForm(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.post(
      uri,
      headers: headers,
      body: fields != null ? Uri(queryParameters: fields).query : null,
    );
    return _handle(response);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = path.startsWith('http') 
        ? Uri.parse(path) 
        : _buildUri(path);
    final response = await _client.get(uri, headers: headers);
    return _handle(response);
  }

  Uri _buildUri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    // Kiểm tra nếu path bắt đầu với /api/resource, /api/workspaces, etc. thì dùng s3BaseUrl
    if (path.startsWith('/api/resource') || 
        path.startsWith('/api/workspaces') ||
        path.startsWith('/api/resource/')) {
      return Uri.parse('${ApiEndpoints.s3BaseUrl}$path');
    }
    return Uri.parse('${ApiEndpoints.baseUrl}$path');
  }

  http.Response _handle(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) return response;
    late String message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] as String? ??
            decoded['error'] as String? ??
            decoded['error_description'] as String? ??
            response.reasonPhrase ??
            '';
      } else if (decoded is String) {
        message = decoded;
      } else {
        message = response.reasonPhrase ?? 'Unexpected error';
      }
    } catch (_) {
      message = response.reasonPhrase ?? 'Unexpected error';
      if (response.body.isNotEmpty) {
        message = '$message\n${response.body}';
      }
    }
    
    // Thông báo rõ ràng hơn cho các lỗi phổ biến
    if (response.statusCode == 401) {
      message = message.isEmpty 
          ? 'Tên đăng nhập hoặc mật khẩu không đúng' 
          : 'Đăng nhập thất bại: $message';
    } else if (response.statusCode == 405) {
      message = message.isEmpty
          ? 'Phương thức HTTP không được hỗ trợ. Endpoint có thể yêu cầu GET hoặc format khác.'
          : 'Method Not Allowed: $message';
    }
    
    throw ApiException(message, statusCode: response.statusCode);
  }

  void dispose() {
    _client.close();
  }
}

