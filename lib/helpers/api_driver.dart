// lib/api_driver.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class APIDriver {
  final String _baseUrl = 'http://10.0.2.2:8001/api';
  final TokenStorage _tokenStorage = TokenStorage();

  // Login
  Future<void> login(String username, String password) async {
    final url = '$_baseUrl/auth/sign-in';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      final expiration = DateTime.now().add(Duration(minutes: 5));

      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveExpirationToken(expiration);
      await _tokenStorage.saveRefreshToken(refreshToken);
    } else {
      throw Exception("Login gagal:" + jsonDecode(response.body)['message']);
    }
  }

  // Register
  Future<void> register(Map<String, dynamic> userData) async {
    final url = '$_baseUrl/register';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      // Registrasi berhasil
    } else {
      throw Exception('Registrasi gagal:' + response.body);
    }
  }

  // Refresh Token
  Future<void> refresh() async {
    final url = '$_baseUrl/auth/token-refresh';
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null) {
      throw Exception('No refresh token found');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access'];
      final expiration = DateTime.now().add(Duration(minutes: 5));

      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveExpirationToken(expiration);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  // GET Request
  Future<http.Response> get(String url) async {
    final accessToken = await _tokenStorage.getAccessToken();
    final expiration = await _tokenStorage.getExpirationToken();

    if (accessToken == null ||
        expiration == null ||
        expiration.isBefore(DateTime.now())) {
      await refresh();
    }

    final response = await http.get(
      Uri.parse('$_baseUrl$url'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to get data: ${response.body}');
    }
  }

  // POST Request
  Future<http.Response> post(String url, Map<String, dynamic> payload) async {
    final accessToken = await _tokenStorage.getAccessToken();
    final expiration = await _tokenStorage.getExpirationToken();

    if (accessToken == null ||
        expiration == null ||
        expiration.isBefore(DateTime.now())) {
      await refresh();
    }

    final response = await http.post(
      Uri.parse('$_baseUrl$url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to post data');
    }
  }

  // PUT Request
  Future<http.Response> put(String url, Map<String, dynamic> payload) async {
    final accessToken = await _tokenStorage.getAccessToken();
    final expiration = await _tokenStorage.getExpirationToken();

    if (accessToken == null ||
        expiration == null ||
        expiration.isBefore(DateTime.now())) {
      await refresh();
    }

    final response = await http.put(
      Uri.parse('$_baseUrl$url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to put data');
    }
  }

  // DELETE Request
  Future<http.Response> delete(String url) async {
    final accessToken = await _tokenStorage.getAccessToken();
    final expiration = await _tokenStorage.getExpirationToken();

    if (accessToken == null ||
        expiration == null ||
        expiration.isBefore(DateTime.now())) {
      await refresh();
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl$url'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response;
    } else {
      throw Exception('Failed to delete data');
    }
  }
}