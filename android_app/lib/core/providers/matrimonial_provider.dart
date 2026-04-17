import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MatrimonialUser {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String religion;
  final String location;
  final String maritalStatus;
  final String description;
  final List<String> images;
  final DateTime createdAt;

  MatrimonialUser({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.religion,
    required this.location,
    required this.maritalStatus,
    required this.description,
    required this.images,
    required this.createdAt,
  });

  factory MatrimonialUser.fromJson(Map<String, dynamic> json) {
    return MatrimonialUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      religion: json['religion'] ?? '',
      location: json['location'] ?? '',
      maritalStatus: json['marital_status'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class MatrimonialAgency {
  final String id;
  final String businessName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String verificationStatus;
  final String description;
  final List<String> images;

  MatrimonialAgency({
    required this.id,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.verificationStatus,
    required this.description,
    required this.images,
  });

  factory MatrimonialAgency.fromJson(Map<String, dynamic> json) {
    return MatrimonialAgency(
      id: json['id'] ?? '',
      businessName: json['business_name'] ?? '',
      contactPerson: json['contact_person'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      verificationStatus: json['verification_status'] ?? 'unverified',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class MatrimonialProvider extends ChangeNotifier {
  final ApiService _apiService;

  MatrimonialProvider(this._apiService);

  List<MatrimonialUser> _users = [];
  List<MatrimonialAgency> _agencies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatrimonialUser> get users => _users;
  List<MatrimonialAgency> get agencies => _agencies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMatrimonialUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/matrimonial/users');
      if (response is List) {
        _users = response.map((u) => MatrimonialUser.fromJson(u)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMatrimonialAgencies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/matrimonial/agencies');
      if (response is List) {
        _agencies = response.map((a) => MatrimonialAgency.fromJson(a)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registerAsUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/matrimonial/users/register', data: userData);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerAsAgency(Map<String, dynamic> agencyData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/matrimonial/agencies/register', data: agencyData);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestMatch(String userId) async {
    try {
      await _apiService.post('/matrimonial/matches', data: {'target_user_id': userId});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
