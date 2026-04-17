import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<Notice> _notices = [];
  bool _isLoading = false;
  String? _error;
  Notice? _selectedNotice;

  NotificationProvider(this._apiService) {
    fetchNotices();
  }

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Notice? get selectedNotice => _selectedNotice;

  Future<void> fetchNotices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/services/notices');
      
      if (response is List) {
        _notices = response.map((json) => Notice.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        _notices = (response['data'] as List).map((json) => Notice.fromJson(json)).toList();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching notices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method to fetch a single notice by ID
  Future<Notice?> fetchNoticeById(int id) async {
    try {
      final response = await _apiService.get('/services/notices/$id');
      if (response != null) {
        return Notice.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error fetching notice $id: $e');
    }
    return null;
  }

  void setSelectedNotice(Notice notice) {
    _selectedNotice = notice;
    notifyListeners();
  }

  void clearSelectedNotice() {
    _selectedNotice = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}