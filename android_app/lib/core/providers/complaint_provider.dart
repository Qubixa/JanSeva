// lib/core/providers/complaint_provider.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class ComplaintProvider with ChangeNotifier {
  final ApiService _apiService;

  // ── State ────────────────────────────────────────────────────────────────

  List<Complaint> _myComplaints = [];
  List<Complaint> _allComplaints = [];
  Complaint? _selectedComplaint;
  List<ComplaintLog> _selectedComplaintLogs = [];

  List<ComplaintCategory> _categories = [];
  ComplaintStats _stats = const ComplaintStats();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _categoriesLoading = false;
  bool _hasMore = true;

  String? _error;
  int _currentPage = 1;

  double _uploadProgress = 0.0;

  // ── Constructor ──────────────────────────────────────────────────────────

  ComplaintProvider(this._apiService);

  // ── Getters ──────────────────────────────────────────────────────────────

  List<Complaint> get myComplaints => List.unmodifiable(_myComplaints);
  List<Complaint> get complaints => List.unmodifiable(_allComplaints);
  Complaint? get selectedComplaint => _selectedComplaint;
  List<ComplaintLog> get complaintLogs => List.unmodifiable(_selectedComplaintLogs);

  List<ComplaintCategory> get categories => List.unmodifiable(_categories);
  ComplaintStats get stats => _stats;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get categoriesLoading => _categoriesLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  // ── Categories ───────────────────────────────────────────────────────────

  /// Fetches active categories from backend.
  /// Backend returns List[ComplaintCategorySchema] objects (not plain strings).
  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return; // already loaded
    _categoriesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.get('$COMPLAINTS_ENDPOINT/categories');
      if (response is List) {
        _categories = response
            .map((json) =>
                ComplaintCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  // ── Create Complaint ─────────────────────────────────────────────────────

  /// Submits a new complaint as multipart/form-data.
  /// Backend endpoint: POST /complaints/  (Form fields + optional media_files)
  Future<bool> createComplaint({
    required String title,
    required String description,
    required String category,
    required String address,
    double? latitude,
    double? longitude,
    List<File>? imageFiles,
  }) async {
    _isSubmitting = true;
    _uploadProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      // Build multipart form
      final fields = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'address': address,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      };

      if (imageFiles != null && imageFiles.isNotEmpty) {
        fields['media_files'] = await Future.wait(
          imageFiles.map(
            (f) => MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            ),
          ),
        );
      }

      final formData = FormData.fromMap(fields);

      final response = await _apiService.postFormData(
        COMPLAINTS_ENDPOINT,
        formData: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      final created = Complaint.fromJson(response as Map<String, dynamic>);
      _myComplaints.insert(0, created);
      _stats = ComplaintStats.fromComplaints(_myComplaints);

      _isSubmitting = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── My Complaints (citizen's own) ────────────────────────────────────────

  /// Backend: GET /complaints/my?page=N&page_size=N&status=X
  /// Supports pagination and optional status filter.
  Future<void> fetchMyComplaints({
    bool refresh = false,
    String? statusFilter,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _myComplaints = [];
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'page_size': PAGE_SIZE,
        if (statusFilter != null && statusFilter.isNotEmpty)
          'status': statusFilter,
      };

      final response = await _apiService.get(
        '$COMPLAINTS_ENDPOINT/my',
        queryParameters: params,
      );

      final fetched = _parseComplaintList(response);
      final total = _parseTotal(response);

      _myComplaints.addAll(fetched);
      _hasMore = _myComplaints.length < total;
      _currentPage++;
      _stats = ComplaintStats.fromComplaints(_myComplaints);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── All Complaints (admin / officer views) ────────────────────────────────

  Future<void> fetchAllComplaints({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        COMPLAINTS_ENDPOINT,
        queryParameters: {'page': page, 'page_size': PAGE_SIZE},
      );
      _allComplaints = _parseComplaintList(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Complaint Detail ─────────────────────────────────────────────────────

  Future<void> fetchComplaintDetails(int complaintId) async {
    _isLoading = true;
    _error = null;
    _selectedComplaintLogs = [];
    notifyListeners();

    try {
      final response =
          await _apiService.get('$COMPLAINTS_ENDPOINT/$complaintId');
      _selectedComplaint =
          Complaint.fromJson(response as Map<String, dynamic>);

      // Also fetch logs (non-blocking failure)
      await _fetchComplaintLogs(complaintId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchComplaintLogs(int complaintId) async {
    try {
      final response =
          await _apiService.get('$COMPLAINTS_ENDPOINT/$complaintId/logs');
      if (response is List) {
        _selectedComplaintLogs = response
            .map((json) =>
                ComplaintLog.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Silent fail — logs are supplementary
    }
  }

  // ── Feedback ─────────────────────────────────────────────────────────────

  Future<bool> submitFeedback({
    required int complaintId,
    required int rating,
    required String feedback,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post(
        '$COMPLAINTS_ENDPOINT/$complaintId/feedback',
        data: {'rating': rating, 'feedback': feedback},
      );
      // Refresh the detail view
      await fetchComplaintDetails(complaintId);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

// Add this to ComplaintProvider class

List<Complaint> _parseComplaintList(dynamic response) {
  debugPrint('Response type: ${response.runtimeType}');
  
  try {
    if (response == null) {
      debugPrint('Response is null');
      return [];
    }
    
    if (response is Map && response.containsKey('complaints')) {
      final complaintsList = response['complaints'];
      if (complaintsList is! List) {
        debugPrint('Complaints is not a list: ${complaintsList.runtimeType}');
        return [];
      }
      debugPrint('Found ${complaintsList.length} complaints');
      return complaintsList
          .where((j) => j != null)
          .map((j) {
            try {
              return Complaint.fromJson(j as Map<String, dynamic>?);
            } catch (e, stackTrace) {
              debugPrint('Error parsing complaint: $e');
              debugPrint('Stack trace: $stackTrace');
              return null;
            }
          })
          .whereType<Complaint>()
          .toList();
    }
    
    if (response is List) {
      debugPrint('Response is a list with ${response.length} items');
      return response
          .where((j) => j != null)
          .map((j) => Complaint.fromJson(j as Map<String, dynamic>?))
          .whereType<Complaint>()
          .toList();
    }
    
    debugPrint('Unexpected response format: $response');
    return [];
  } catch (e) {
    debugPrint('Failed to parse complaints: $e');
    return [];
  }
}

int _parseTotal(dynamic response) {
  if (response is Map && response.containsKey('total')) {
    return (response['total'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

  // ── Cleanup ──────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedComplaint() {
    _selectedComplaint = null;
    _selectedComplaintLogs = [];
    notifyListeners();
  }

  void resetMyComplaints() {
    _myComplaints = [];
    _currentPage = 1;
    _hasMore = true;
    _stats = const ComplaintStats();
    notifyListeners();
  }
}