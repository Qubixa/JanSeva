import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  late SharedPreferences _prefs;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService);

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isCitizen => _user?.role == CITIZEN_ROLE;
  bool get isWardAdmin => _user?.role == WARD_ADMIN_ROLE;
  bool get isSuperAdmin => _user?.role == SUPER_ADMIN_ROLE;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedData();
  }

  void _loadSavedData() {
    final savedToken = _prefs.getString(TOKEN_STORAGE_KEY);
    final savedUserJson = _prefs.getString(USER_STORAGE_KEY);

    if (savedToken != null && savedUserJson != null) {
      try {
        _token = savedToken;
        _user = User.fromJson(jsonDecode(savedUserJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading saved data: $e');
        _clearSavedData();
      }
    }
  }

  Future<void> _clearSavedData() async {
    await _prefs.remove(TOKEN_STORAGE_KEY);
    await _prefs.remove(USER_STORAGE_KEY);
  }

  Future<bool> login(String mobile, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 Attempting login for mobile: $mobile');

      final response = await _apiService.post(
        LOGIN_ENDPOINT,
        data: {
          'mobile': mobile,
          'password': password,
        },
      );

      debugPrint('✅ Login response received');
      debugPrint('Response data: ${jsonEncode(response)}');

      final authResponse = AuthResponse.fromJson(response);
      _token = authResponse.accessToken;
      _user = authResponse.user;

      debugPrint('✅ User logged in: ${_user?.name} (${_user?.mobile})');

      await _apiService.setToken(_token!);
      await _prefs.setString(TOKEN_STORAGE_KEY, _token!);
      await _prefs.setString(USER_STORAGE_KEY, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String mobile,
    required String password,
    required String confirmPassword,
    required int wardId,
    required String address,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📝 Attempting registration for mobile: $mobile');

      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      final response = await _apiService.post(
        REGISTER_ENDPOINT,
        data: {
          'name': name,
          'mobile': mobile,
          'password': password,
          'confirm_password': confirmPassword,
          'ward_id': wardId,
          'address': address,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      debugPrint('✅ Registration response received');

      final authResponse = AuthResponse.fromJson(response);
      _token = authResponse.accessToken;
      _user = authResponse.user;

      await _apiService.setToken(_token!);
      await _prefs.setString(TOKEN_STORAGE_KEY, _token!);
      await _prefs.setString(USER_STORAGE_KEY, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Try to call logout endpoint, but don't fail if it errors
      await _apiService.post(LOGOUT_ENDPOINT).catchError((e) {
        debugPrint('Logout endpoint error (ignoring): $e');
      });
    } catch (e) {
      debugPrint('Logout error (ignoring): $e');
    }

    _token = null;
    _user = null;
    _error = null;
    await _apiService.clearToken();
    await _clearSavedData();
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (address != null) data['address'] = address;

      final response = await _apiService.put(
        PROFILE_ENDPOINT,
        data: data,
      );

      final updatedUser = User.fromJson(response);
      _user = updatedUser;
      await _prefs.setString(USER_STORAGE_KEY, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post(
        CHANGE_PASSWORD_ENDPOINT,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Change password error: $e');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}