import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = '192.168.1.15';
  static const String rapidApiKey =
      'a81359cf3dmsha7941111e8271a7p1b07f5jsn39ce879b3ea2';
  static const String exerciseDbHost = 'exercisedb.p.rapidapi.com';
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

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
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
      body: body.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&'),
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
    throw ApiException(
      data['detail'] ?? 'Something went wrong',
      res.statusCode,
    );
  }

  static Future<Map<String, dynamic>?> fetchExerciseData(
    String exerciseName,
  ) async {
    try {
      final encoded = Uri.encodeComponent(exerciseName.toLowerCase().trim());
      final res = await http.get(
        Uri.parse('$baseUrl/workout/exercise-gif/$encoded'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final originalGifUrl = data['gif_url'] as String? ?? '';

        // ✅ Rewrite GIF URL to go through our backend proxy
        if (originalGifUrl.isNotEmpty) {
          final proxiedUrl =
              '$baseUrl/workout/exercise-gif-image?url='
              '${Uri.encodeComponent(originalGifUrl)}';
          data['gif_url'] = proxiedUrl;
        }
        return data;
      }
    } catch (e) {
      print('❌ API client error: $e');
    }
    return null;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
