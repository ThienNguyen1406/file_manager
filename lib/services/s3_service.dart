import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../constants/api_endpoints.dart';

class S3Service {
  S3Service(this._client);

  final ApiClient _client;

  /// Fetch resources với pagination
  /// Có thể filter theo parentId để lấy children của một folder cụ thể
  Future<Map<String, dynamic>> fetchResources({
    required String token,
    int pageOffset = 1,
    int pageSize = 20,
    String? parentId,
  }) async {
    String url = ApiEndpoints.s3ResourceWithPagination(
      pageOffset: pageOffset,
      pageSize: pageSize,
    );
    // Thêm parentId vào query nếu có
    if (parentId != null && parentId.isNotEmpty) {
      url += '&parentId=$parentId';
    }
    final response = await _client.get(url, headers: _headers(token));
    return _decodeMap(response.body);
  }

  /// Fetch workspaces
  Future<List<dynamic>> fetchWorkspaces(String token) async {
    final response = await _client.get(
      ApiEndpoints.s3Workspaces,
      headers: _headers(token),
    );
    return _decodeList(response.body);
  }

  /// Fetch resource size
  Future<Map<String, dynamic>> fetchResourceSize(String token) async {
    final response = await _client.get(
      ApiEndpoints.s3ResourceSize,
      headers: _headers(token),
    );
    return _decodeMap(response.body);
  }

  /// Fetch resource tab với pagination
  /// Thử GET trước, nếu lỗi 405 thì thử POST
  Future<Map<String, dynamic>> fetchResourceTab({
    required String token,
    int pageOffset = 1,
    int pageSize = 30,
  }) async {
    final url = ApiEndpoints.s3ResourceTabWithPagination(
      pageOffset: pageOffset,
      pageSize: pageSize,
    );

    // Thử GET trước
    try {
      final response = await _client.get(url, headers: _headers(token));
      return _decodeMap(response.body);
    } on ApiException catch (e) {
      // Nếu lỗi 405, thử POST với body là JSON
      if (e.statusCode == 405) {
        try {
          final body = jsonEncode({
            'pageOffset': pageOffset,
            'pageSize': pageSize,
          });
          final response = await _client.post(
            ApiEndpoints.s3ResourceTab,
            headers: _headers(token),
            body: body,
          );
          return _decodeMap(response.body);
        } catch (e2) {
          // Nếu POST cũng lỗi, trả về empty map thay vì throw
          // Để app không crash, caller sẽ xử lý empty data
          if (kDebugMode) {
            debugPrint(
                '⚠️ S3Service: Both GET and POST failed for resource tab');
            debugPrint('   GET error: $e');
            debugPrint('   POST error: $e2');
          }
          return {'error': 'Failed to fetch resource tab', 'data': []};
        }
      }
      // Nếu không phải lỗi 405, trả về empty map thay vì throw
      if (kDebugMode) {
        debugPrint('⚠️ S3Service: GET failed for resource tab: $e');
      }
      return {'error': e.message, 'data': []};
    } catch (e) {
      // Catch mọi lỗi khác, trả về empty map
      if (kDebugMode) {
        debugPrint('⚠️ S3Service: Unexpected error fetching resource tab: $e');
      }
      return {'error': e.toString(), 'data': []};
    }
  }

  /// Fetch resource details
  Future<Map<String, dynamic>> fetchResourceDetails({
    required String token,
    required String resourceId,
  }) async {
    final url = ApiEndpoints.s3ResourceDetailsWithId(resourceId);
    final response = await _client.get(url, headers: _headers(token));
    return _decodeMap(response.body);
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  List<dynamic> _decodeList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic>) {
        // Thử nhiều key khác nhau
        if (decoded.containsKey('data') && decoded['data'] is List) {
          return decoded['data'] as List;
        }
        if (decoded.containsKey('content') && decoded['content'] is List) {
          return decoded['content'] as List;
        }
        if (decoded.containsKey('items') && decoded['items'] is List) {
          return decoded['items'] as List;
        }
        if (decoded.containsKey('results') && decoded['results'] is List) {
          return decoded['results'] as List;
        }
        // Nếu có key đầu tiên là List
        for (final value in decoded.values) {
          if (value is List) return value;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Nếu là List, lấy phần tử đầu tiên
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return decoded.first as Map<String, dynamic>;
      }
      return {'raw': decoded.toString()};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
