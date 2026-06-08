import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiService {
  static String accessToken = '';
  static String refreshToken = '';

  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> get authHeaders {
    final headers = Map<String, String>.from(defaultHeaders);
    if (accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      return _normalizeResponse(response);
    } catch (_) {
      return {
        'statusCode': 0,
        'body': {'message': 'Network error. Check your connection.'},
      };
    }
  }

  static Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/register'),
          headers: defaultHeaders,
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'password': password,
          }),
        ),
      );

  static Future<Map<String, dynamic>> verifyEmail(
    String email,
    String otp,
  ) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/verify-email'),
          headers: defaultHeaders,
          body: jsonEncode({'email': email, 'otp': otp}),
        ),
      );

  static Future<Map<String, dynamic>> resendOtp(String email) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/resend-otp'),
          headers: defaultHeaders,
          body: jsonEncode({'email': email}),
        ),
      );

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/login'),
          headers: defaultHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        ),
      );

  static Future<Map<String, dynamic>> getProfile() =>
      _safeRequest(
        () => http.get(
          Uri.parse('${AppTheme.backendBaseUrl}/api/user/profile'),
          headers: authHeaders,
        ),
      );

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? gender,
  }) =>
      _safeRequest(
        () => http.put(
          Uri.parse('${AppTheme.backendBaseUrl}/api/user/profile'),
          headers: authHeaders,
          body: jsonEncode({
            if (fullName != null) 'full_name': fullName,
            if (username != null) 'username': username,
            if (gender != null) 'gender': gender,
          }),
        ),
      );

  static Future<Map<String, dynamic>> updateQuestionnaire({
    required String skinType,
    required List<String> skinConcerns,
    required String allergies,
    required String environment,
    required List<String> goals,
  }) =>
      _safeRequest(
        () => http.put(
          Uri.parse('${AppTheme.backendBaseUrl}/api/user/questionnaire'),
          headers: authHeaders,
          body: jsonEncode({
            'skin_type': skinType,
            'skin_concerns': skinConcerns,
            'allergies': allergies,
            'environment': environment,
            'goals': goals,
          }),
        ),
      );

  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/forgot-password'),
          headers: defaultHeaders,
          body: jsonEncode({'email': email}),
        ),
      );

  static Future<Map<String, dynamic>> verifyResetOtp(
    String email,
    String otp,
  ) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/verify-reset-otp'),
          headers: defaultHeaders,
          body: jsonEncode({'email': email, 'otp': otp}),
        ),
      );

  static Future<Map<String, dynamic>> resetPassword(
    String resetToken,
    String newPassword,
  ) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/auth/reset-password'),
          headers: defaultHeaders,
          body: jsonEncode({
            'reset_token': resetToken,
            'new_password': newPassword,
          }),
        ),
      );

  static Future<Map<String, dynamic>> createSkinProfile({
    required String skinType,
    required List<String> skinConcerns,
    required String allergies,
    required String environment,
    required List<String> goals,
  }) =>
      _safeRequest(
        () => http.post(
          Uri.parse('${AppTheme.backendBaseUrl}/api/skin-profile'),
          headers: authHeaders,
          body: jsonEncode({
            'skin_type': skinType,
            'skin_concerns': skinConcerns,
            'allergies': allergies,
            'environment': environment,
            'goals': goals,
          }),
        ),
      );

  static Map<String, dynamic> _normalizeResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }
    return {'statusCode': response.statusCode, 'body': body};
  }
}
