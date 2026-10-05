import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'core/network/api_constants.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => message;
}

class Api {
  Api(this.token);

  final String? token;
  static const _timeout = Duration(seconds: 12);

  Future<({String token, AppUser user})> login(String email, String password) async {
    final data = await _send('/api/auth/login', method: 'POST', body: {'email': email, 'password': password}, auth: false);
    return (token: data['token'] as String, user: AppUser.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<AppUser> me() async {
    final data = await _send('/api/auth/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<Receipt>> receipts() async {
    final data = await _send('/api/receipts');
    final rows = data['receipts'] as List<dynamic>;
    return rows.map((row) => Receipt.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<Receipt> receipt(int id) async {
    final data = await _send('/api/receipts/$id');
    return Receipt.fromJson(data['receipt'] as Map<String, dynamic>);
  }

  Future<Receipt> createReceipt(Map<String, dynamic> body) async {
    final data = await _send('/api/receipts', method: 'POST', body: body);
    return Receipt.fromJson(data['receipt'] as Map<String, dynamic>);
  }

  Future<List<int>> receiptPdf(int id) async {
    final response = await _guard(() => http.get(_uri('/api/receipts/$id/pdf'), headers: _headers()).timeout(_timeout));
    if (response.statusCode >= 400) {
      throw ApiException(_errorMessage(response), status: response.statusCode);
    }
    return response.bodyBytes;
  }

  Map<String, String> _headers({bool json = false}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) {
    var base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/api') && path.startsWith('/api/')) {
      base = base.substring(0, base.length - 4);
    }
    return Uri.parse('$base$path');
  }

  Future<Map<String, dynamic>> _send(String path, {String method = 'GET', Map<String, dynamic>? body, bool auth = true}) async {
    final headers = _headers(json: body != null);
    if (!auth) headers.remove('Authorization');
    final uri = _uri(path);
    final response = await _guard(() {
      if (method == 'POST') {
        return http.post(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
      }
      return http.get(uri, headers: headers).timeout(_timeout);
    });
    if (response.statusCode >= 400) {
      throw ApiException(_errorMessage(response), status: response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TimeoutException {
      throw ApiException('Could not reach the server. Check Wi-Fi and that the API is running.');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Could not reach the server. Check Wi-Fi and that the API is running.');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['error'] is String) return data['error'] as String;
    } catch (_) {}
    return 'Could not reach the server';
  }
}
