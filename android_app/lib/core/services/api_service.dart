import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  late Dio _dio;
  late SharedPreferences _prefs;

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
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for logging and token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('🌐 REQUEST[${options.method}] => ${options.uri}');
            debugPrint('Headers: ${options.headers}');
            debugPrint('Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
            debugPrint('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}');
            debugPrint('Error: ${error.message}');
            debugPrint('Response: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String?> _getToken() async {
    return _prefs.getString(TOKEN_STORAGE_KEY);
  }

  Future<void> setToken(String token) async {
    await _prefs.setString(TOKEN_STORAGE_KEY, token);
    _initializeDio();
  }

  Future<void> clearToken() async {
    await _prefs.remove(TOKEN_STORAGE_KEY);
    await _prefs.remove(USER_STORAGE_KEY);
  }

  // GET Request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
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

  // POST Request
  Future<dynamic> post(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters}) async {
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

  // PUT Request
  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  // Upload File with FormData
  Future<dynamic> uploadFile(String endpoint, String filePath, {Map<String, dynamic>? additionalData}) async {
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

  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final responseData = error.response!.data;

        // Try to extract error message from response
        String message = 'An error occurred';

        if (responseData is Map<String, dynamic>) {
          // Try different error message keys
          message = responseData['detail'] ??
              responseData['message'] ??
              responseData['error'] ??
              message;
        } else if (responseData is String) {
          message = responseData;
        }

        throw ApiException(message, statusCode ?? 500);
      } else if (error.type == DioExceptionType.connectionTimeout) {
        throw ApiException('Connection timeout. Please check your internet connection.', 0);
      } else if (error.type == DioExceptionType.receiveTimeout) {
        throw ApiException('Server response timeout. Please try again.', 0);
      } else {
        throw ApiException('Connection error. Please check your internet connection.', 0);
      }
    } else {
      throw ApiException('An unexpected error occurred: $error', 500);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}