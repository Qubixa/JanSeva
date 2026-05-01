import 'package:flutter/material.dart';
import '../models/service_models.dart';
import '../models/ward_model.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class ServicesProvider with ChangeNotifier {
  final ApiService _apiService;

  List<EmergencyService> _emergencyServices = [];
  List<Scheme> _schemes = [];
  List<TransportInfo> _transportInfo = [];
  List<Contact> _contacts = [];
  List<Ward> _wards = [];
  Ward? _selectedWard;

  bool _isLoading = false;
  String? _error;

  ServicesProvider(this._apiService);

  // Getters
  List<EmergencyService> get emergencyServices => _emergencyServices;
  List<Scheme> get schemes => _schemes;
  List<TransportInfo> get transportInfo => _transportInfo;
  List<Contact> get contacts => _contacts;
  List<Ward> get wards => _wards;
  Ward? get selectedWard => _selectedWard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters
  void setSelectedWard(Ward? ward) {
    _selectedWard = ward;
    notifyListeners();
  }

  Future<void> fetchWards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(WARDS_ENDPOINT);

      if (response is List) {
        _wards = response.map((json) => Ward.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _wards = (response['data'] as List).map((json) => Ward.fromJson(json)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEmergencyServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(EMERGENCY_SERVICES_ENDPOINT);

      if (response is List) {
        _emergencyServices = response.map((json) => EmergencyService.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _emergencyServices = (response['data'] as List)
            .map((json) => EmergencyService.fromJson(json))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSchemes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(SCHEMES_ENDPOINT);

      if (response is List) {
        _schemes = response.map((json) => Scheme.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _schemes = (response['data'] as List).map((json) => Scheme.fromJson(json)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransportInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(TRANSPORT_ENDPOINT);

      if (response is List) {
        _transportInfo = response.map((json) => TransportInfo.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _transportInfo = (response['data'] as List).map((json) => TransportInfo.fromJson(json)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(CONTACTS_ENDPOINT);

      if (response is List) {
        _contacts = response.map((json) => Contact.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _contacts = (response['data'] as List).map((json) => Contact.fromJson(json)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
