import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class ComplaintProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Complaint> _complaints = [];
  List<Complaint> _myComplaints = [];
  Complaint? _selectedComplaint;
  bool _isLoading = false;
  String? _error;
  List<String> _categories = [];
  bool _categoriesLoading = false;

  ComplaintProvider(this._apiService);

  // Getters
  List<Complaint> get complaints => _complaints;
  List<Complaint> get myComplaints => _myComplaints;
  Complaint? get selectedComplaint => _selectedComplaint;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;

  Future<void> fetchCategories() async {
    _categoriesLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch categories from backend
      final response = await _apiService.get('$COMPLAINTS_ENDPOINT/categories');
      if (response is List) {
        _categories = List<String>.from(response);
      } else if (response is Map && response['categories'] is List) {
        _categories = List<String>.from(response['categories']);
      }
      _categoriesLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createComplaint({
    required String title,
    required String description,
    required String category,
    required String address,
    double? latitude,
    double? longitude,
    String? imagePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'title': title,
        'description': description,
        'category': category,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await _apiService.post(
        CREATE_COMPLAINT_ENDPOINT,
        data: data,
      );

      final complaint = Complaint.fromJson(response);
      _complaints.insert(0, complaint);
      _myComplaints.insert(0, complaint);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyComplaints({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '$COMPLAINTS_ENDPOINT/my',
        queryParameters: {
          'skip': (page - 1) * PAGE_SIZE,
          'limit': PAGE_SIZE,
        },
      );

      if (response is List) {
        _myComplaints = response.map((json) => Complaint.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _myComplaints = (response['data'] as List)
            .map((json) => Complaint.fromJson(json))
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

  Future<void> fetchAllComplaints({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        COMPLAINTS_ENDPOINT,
        queryParameters: {
          'skip': (page - 1) * PAGE_SIZE,
          'limit': PAGE_SIZE,
        },
      );

      if (response is List) {
        _complaints = response.map((json) => Complaint.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _complaints = (response['data'] as List)
            .map((json) => Complaint.fromJson(json))
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

  Future<void> fetchComplaintDetails(int complaintId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('$COMPLAINT_DETAILS_ENDPOINT/$complaintId');
      _selectedComplaint = Complaint.fromJson(response);
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

  void clearSelectedComplaint() {
    _selectedComplaint = null;
    notifyListeners();
  }
}
