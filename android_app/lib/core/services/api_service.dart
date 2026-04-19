// lib/core/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  late Dio _dio;
  late SharedPreferences _prefs;
  bool _initialized = false;

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: API_BASE_URL,
        connectTimeout: const Duration(milliseconds: CONNECTION_TIMEOUT),
        receiveTimeout: const Duration(milliseconds: RECEIVE_TIMEOUT),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Do NOT set Content-Type here — Dio sets it correctly for FormData
          if (options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          }

          if (kDebugMode) {
            debugPrint('🌐 [${options.method}] ${options.uri}');
            if (options.data is! FormData) {
              debugPrint('   Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ [${response.statusCode}] ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('❌ [${error.response?.statusCode}] ${error.requestOptions.uri}');
            debugPrint('   ${error.message}');
            debugPrint('   ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<String?> _getToken() async {
    if (!_initialized) await initialize();
    return _prefs.getString(TOKEN_STORAGE_KEY);
  }

  Future<void> setToken(String token) async {
    if (!_initialized) await initialize();
    await _prefs.setString(TOKEN_STORAGE_KEY, token);
  }

  Future<void> clearToken() async {
    if (!_initialized) await initialize();
    await _prefs.remove(TOKEN_STORAGE_KEY);
    await _prefs.remove(USER_STORAGE_KEY);
  }

  // ── GET ──────────────────────────────────────────────────────────────────

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // ── POST (JSON) ──────────────────────────────────────────────────────────

  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // ── POST (multipart / FormData) ──────────────────────────────────────────

  Future<dynamic> postFormData(
    String endpoint, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          // Let Dio figure out multipart boundary automatically
          contentType: 'multipart/form-data',
        ),
      );
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // ── PUT ──────────────────────────────────────────────────────────────────

  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────────

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // ── Upload (legacy single file) ──────────────────────────────────────────

  Future<dynamic> uploadFile(
    String endpoint,
    String filePath, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (additionalData != null) ...additionalData,
      });
      final response = await _dio.post(endpoint, data: formData);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // ── Error handling ───────────────────────────────────────────────────────

  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode ?? 500;
        final responseData = error.response!.data;

        String message = 'An error occurred';
        if (responseData is Map<String, dynamic>) {
          message = (responseData['detail'] ??
                  responseData['message'] ??
                  responseData['error'] ??
                  message)
              .toString();
        } else if (responseData is String && responseData.isNotEmpty) {
          message = responseData;
        }

        throw ApiException(message, statusCode);
      } else {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
            throw ApiException(
                'Connection timeout. Please check your internet.', 0);
          case DioExceptionType.receiveTimeout:
            throw ApiException('Server not responding. Try again.', 0);
          case DioExceptionType.sendTimeout:
            throw ApiException('Upload timed out. Try a smaller file.', 0);
          case DioExceptionType.cancel:
            throw ApiException('Request was cancelled.', 0);
          default:
            throw ApiException(
                'Network error. Please check your connection.', 0);
        }
      }
    } else if (error is ApiException) {
  throw error;
} else {
      throw ApiException('Unexpected error: $error', 500);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => message;
}