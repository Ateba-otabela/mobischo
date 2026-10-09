import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobischo/models/user.dart';

class MobileApiService {
  static const _tokenKey = 'mobischo_auth_token';
  static const _userKey = 'mobischo_auth_user';
  static const _baseUrl = 'https://mobischo.com/api';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static String? _sessionToken;
  static User? _currentUser;
  static final Set<String> _registeredFcmTokens = <String>{};
  static final Map<String, Future<bool>> _deviceRegistrationRequests = {};
  static int _sessionGeneration = 0;
  static bool _logoutInProgress = false;

  static String? get currentToken => _sessionToken;
  static User? get currentUser => _currentUser;
  static String get devicePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static Future<void> saveSession(User user, String token) async {
    _sessionGeneration++;
    _registeredFcmTokens.clear();
    _deviceRegistrationRequests.clear();
    _logoutInProgress = false;
    _sessionToken = token;
    _currentUser = user;

    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: token),
      _secureStorage.write(
        key: _userKey,
        value: jsonEncode({
          'nom': user.nom,
          'prenom': user.prenom,
          'contacts': user.contacts,
          'sex': user.sex,
          'email': user.email,
          'login': user.login,
          'code': user.code,
          'account_type': user.account_type,
          'text_password': user.text_password,
          'address': user.address,
          'admin': user.admin,
          'CodeEtablissement': user.CodeEtablissement,
          'ai_token': user.aiToken,
        }),
      ),
    ]);
  }

  static Future<String?> loadToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (_sessionToken != token) {
      _sessionGeneration++;
      _registeredFcmTokens.clear();
      _deviceRegistrationRequests.clear();
    }
    _sessionToken = token;
    return token;
  }

  static Future<bool> registerDevice(String fcmToken, String platform) async {
    try {
      final token = fcmToken.trim();
      if (token.isEmpty ||
          !['android', 'ios'].contains(platform) ||
          _logoutInProgress) {
        return false;
      }

      final sanctumToken = _sessionToken ?? await loadToken();
      if (_logoutInProgress || sanctumToken == null || sanctumToken.isEmpty) {
        return false;
      }

      if (_registeredFcmTokens.contains(token)) return true;

      final inFlight = _deviceRegistrationRequests[token];
      if (inFlight != null) return inFlight;

      final generation = _sessionGeneration;
      final request = _sendDeviceRegistration(
        token,
        platform,
        sanctumToken,
        generation,
      );
      _deviceRegistrationRequests[token] = request;

      try {
        final registered = await request;
        if (registered &&
            generation == _sessionGeneration &&
            !_logoutInProgress) {
          _registeredFcmTokens.add(token);
        }
        return registered;
      } finally {
        if (identical(_deviceRegistrationRequests[token], request)) {
          _deviceRegistrationRequests.remove(token);
        }
      }
    } on Exception catch (error) {
      _logDeviceRegistrationFailure(error.runtimeType.toString());
      return false;
    }
  }

  static Future<bool> _sendDeviceRegistration(
    String fcmToken,
    String platform,
    String sanctumToken,
    int generation,
  ) async {
    try {
      final headers = await buildHeaders(extra: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

      if (_logoutInProgress ||
          generation != _sessionGeneration ||
          _sessionToken != sanctumToken) {
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/notifications/devices'),
            headers: headers,
            body: jsonEncode({
              'fcm_token': fcmToken,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      _logDeviceRegistrationFailure('HTTP ${response.statusCode}');
      return false;
    } on Exception catch (error) {
      _logDeviceRegistrationFailure(error.runtimeType.toString());
      return false;
    }
  }

  static void _logDeviceRegistrationFailure(String reason) {
    if (kDebugMode) {
      debugPrint('FCM device registration failed ($reason).');
    }
  }

  static Future<User?> loadSession() async {
    final token = await loadToken();
    final userJson = await _secureStorage.read(key: _userKey);

    if (token == null ||
        token.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      _sessionToken = null;
      _currentUser = null;
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      _currentUser = User.fromJson(decoded);
      return _currentUser;
    } catch (_) {
      _currentUser = null;
      return null;
    }
  }

  static Future<void> clearSession() async {
    _sessionGeneration++;
    _registeredFcmTokens.clear();
    _deviceRegistrationRequests.clear();
    _sessionToken = null;
    _currentUser = null;

    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _userKey),
    ]);
  }

  static Future<Map<String, String>> buildHeaders(
      {Map<String, String>? extra}) async {
    final headers = <String, String>{};

    if (extra != null) {
      headers.addAll(extra);
    }

    final token = _sessionToken ?? await loadToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<http.Response> get(String path,
      {Map<String, String>? headers}) async {
    final finalHeaders = await buildHeaders(extra: headers);
    return http.get(Uri.parse('$_baseUrl$path'), headers: finalHeaders);
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await buildHeaders(extra: headers);
    return http.post(Uri.parse('$_baseUrl$path'),
        headers: finalHeaders, body: body);
  }

  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await buildHeaders(extra: headers);
    return http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: finalHeaders,
      body: body,
    );
  }

  static Future<http.Response> postMultipart(
    String path, {
    required Map<String, String> fields,
    http.MultipartFile? file,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await buildHeaders(extra: headers);
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
      ..headers.addAll(finalHeaders)
      ..fields.addAll(fields);
    if (file != null) {
      request.files.add(file);
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    return http.Response.fromStream(streamedResponse);
  }

  static Future<void> logout() async {
    _logoutInProgress = true;
    try {
      final token = _sessionToken ?? await loadToken();

      if (token != null && token.isNotEmpty) {
        try {
          await http.post(
            Uri.parse('$_baseUrl/mobile/logout'),
            headers: {'Authorization': 'Bearer $token'},
          );
        } catch (_) {
          // Keep the local session clean even when the backend is unreachable.
        }
      }

      await clearSession();
    } finally {
      _logoutInProgress = false;
    }
  }
}
