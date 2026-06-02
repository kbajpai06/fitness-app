import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000';

  // Use SharedPreferences instead of FlutterSecureStorage (works on web)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<dynamic> postForm(String path, Map<String, String> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body.entries.map((e) =>
        '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}'
      ).join('&'),
    );
    return _handle(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(data['detail'] ?? 'Something went wrong', res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}