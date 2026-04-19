// lib/core/providers/matrimonial_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

enum UserType { individual, agency }

class MatrimonialProfile {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final String? religion;
  final String? caste;
  final String? height;
  final String? occupation;
  final String? education;
  final String? location;
  final int? wardId;
  final String? bio;
  final bool isVerified;
  final String? status;
  final DateTime createdAt;
  final bool hasProfileImage;
  final String? profileImageBase64;
  final bool hasBioData;
  final String? bioDataFilename;
  final bool hasKundali;
  final String? kundaliFilename;

  MatrimonialProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.religion,
    this.caste,
    this.height,
    this.occupation,
    this.education,
    this.location,
    this.wardId,
    this.bio,
    this.isVerified = false,
    this.status,
    required this.createdAt,
    this.hasProfileImage = false,
    this.profileImageBase64,
    this.hasBioData = false,
    this.bioDataFilename,
    this.hasKundali = false,
    this.kundaliFilename,
  });

  int get age {
    if (dateOfBirth == null) return 0;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? 'Anonymous';
  }

  // UI compatibility getters
  String? get photoUrl => profileImageBase64 != null 
      ? 'data:image/jpeg;base64,$profileImageBase64' 
      : null;
  
  String get name => displayName;
  
  String? get profession => occupation;
  
  String? get annualIncome => null; // Add to your model if needed
  
  String? get about => bio;
  
  String? get photoBase64 => profileImageBase64;

  factory MatrimonialProfile.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    if (json['date_of_birth'] != null) {
      dob = DateTime.tryParse(json['date_of_birth'].toString());
    }

    return MatrimonialProfile(
      id: json['id'],
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender']?.toString().split('.').last,
      dateOfBirth: dob,
      maritalStatus: json['marital_status']?.toString().split('.').last,
      religion: json['religion'],
      caste: json['caste'],
      height: json['height'],
      occupation: json['occupation'] ?? json['profession'],
      education: json['education'],
      location: json['location'],
      wardId: json['ward_id'],
      bio: json['bio'] ?? json['about'],
      isVerified: json['is_verified'] ?? false,
      status: json['status']?.toString().split('.').last,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      hasProfileImage: json['has_profile_image'] ?? false,
      profileImageBase64: json['profile_image_base64'] ?? json['photoBase64'],
      hasBioData: json['has_bio_data'] ?? false,
      bioDataFilename: json['bio_data_filename'],
      hasKundali: json['has_kundali'] ?? false,
      kundaliFilename: json['kundali_filename'],
    );
  }
}

class MatrimonialAgency {
  final int id;
  final String agencyName;
  final String contactEmail;
  final String phone;
  final String ownerName;
  final String registrationNumber;
  final String location;
  final int? wardId;
  final String? about;
  final bool isVerified;
  final String? status;
  final DateTime createdAt;
  final bool hasLogo;
  final String? logoBase64;

  MatrimonialAgency({
    required this.id,
    required this.agencyName,
    required this.contactEmail,
    required this.phone,
    required this.ownerName,
    required this.registrationNumber,
    required this.location,
    this.wardId,
    this.about,
    this.isVerified = false,
    this.status,
    required this.createdAt,
    this.hasLogo = false,
    this.logoBase64,
  });

  factory MatrimonialAgency.fromJson(Map<String, dynamic> json) {
    return MatrimonialAgency(
      id: json['id'],
      agencyName: json['agency_name'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      phone: json['phone'] ?? '',
      ownerName: json['owner_name'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      location: json['location'] ?? '',
      wardId: json['ward_id'],
      about: json['about'],
      isVerified: json['is_verified'] ?? false,
      status: json['status']?.toString().split('.').last,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      hasLogo: json['has_logo'] ?? false,
      logoBase64: json['logo_base64'],
    );
  }
}

class MatchRequest {
  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final String? message;
  final DateTime createdAt;
  final Map<String, dynamic>? otherParty; // Added for detailed match info

  MatchRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.message,
    required this.createdAt,
    this.otherParty,
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    return MatchRequest(
      id: json['id'],
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      status: json['status'] ?? 'PENDING',
      message: json['message'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      otherParty: json['other_party'],
    );
  }
}

class MatrimonialProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<MatrimonialProfile> _profiles = [];
  List<MatrimonialProfile> _recentProfiles = [];
  List<MatchRequest> _myMatches = [];
  List<MatrimonialAgency> _agencies = [];
  MatrimonialProfile? _currentProfile;
  MatrimonialAgency? _currentAgency;
  bool _isLoading = false;
  bool _isRegistered = false;
  bool _isAgencyRegistered = false;
  int _totalProfiles = 0;
  int _totalAgencies = 0;
  String? _errorMessage;

  // Getters
  List<MatrimonialProfile> get profiles => _profiles;
  List<MatrimonialProfile> get recentProfiles => _recentProfiles;
  List<MatchRequest> get myMatches => _myMatches;
  List<MatrimonialAgency> get agencies => _agencies;
  MatrimonialProfile? get currentProfile => _currentProfile;
  MatrimonialAgency? get currentAgency => _currentAgency;
  bool get isLoading => _isLoading;
  bool get isRegistered => _isRegistered;
  bool get isAgencyRegistered => _isAgencyRegistered;
  int get totalProfiles => _totalProfiles;
  int get totalAgencies => _totalAgencies;
  String? get errorMessage => _errorMessage;

  MatrimonialProvider(this._apiService);

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INDIVIDUAL REGISTRATION (multipart/form-data)
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> registerIndividual({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
    required String maritalStatus,
    required String location,
    String? religion,
    String? caste,
    String? height,
    String? occupation,
    String? education,
    int? wardId,
    String? bio,
    File? profileImage,
    File? bioData,
    File? kundali,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(TOKEN_STORAGE_KEY);
      
      final uri = Uri.parse('$API_BASE_URL/matrimonial/users/register');
      final request = http.MultipartRequest('POST', uri);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['gender'] = gender.toUpperCase();
      request.fields['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
      request.fields['marital_status'] = maritalStatus.toUpperCase();
      request.fields['location'] = location;
      
      if (religion != null && religion.isNotEmpty) request.fields['religion'] = religion;
      if (caste != null && caste.isNotEmpty) request.fields['caste'] = caste;
      if (height != null && height.isNotEmpty) request.fields['height'] = height;
      if (occupation != null && occupation.isNotEmpty) request.fields['occupation'] = occupation;
      if (education != null && education.isNotEmpty) request.fields['education'] = education;
      if (wardId != null) request.fields['ward_id'] = wardId.toString();
      if (bio != null && bio.isNotEmpty) request.fields['bio'] = bio;

      // Add files
      if (profileImage != null) {
        final mimeType = lookupMimeType(profileImage.path) ?? 'image/jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          profileImage.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      if (bioData != null) {
        final mimeType = lookupMimeType(bioData.path) ?? 'application/pdf';
        request.files.add(await http.MultipartFile.fromPath(
          'bio_data',
          bioData.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      if (kundali != null) {
        final mimeType = lookupMimeType(kundali.path) ?? 'application/pdf';
        request.files.add(await http.MultipartFile.fromPath(
          'kundali',
          kundali.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isRegistered = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed: ${response.body}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to register: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AGENCY REGISTRATION
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> registerAgency({
    required String agencyName,
    required String contactEmail,
    required String phone,
    required String ownerName,
    required String registrationNumber,
    required String location,
    int? wardId,
    String? about,
    File? logo,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(TOKEN_STORAGE_KEY);
      
      final uri = Uri.parse('$API_BASE_URL/matrimonial/agencies/register');
      final request = http.MultipartRequest('POST', uri);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      request.fields['agency_name'] = agencyName;
      request.fields['contact_email'] = contactEmail;
      request.fields['phone'] = phone;
      request.fields['owner_name'] = ownerName;
      request.fields['registration_number'] = registrationNumber;
      request.fields['location'] = location;
      
      if (wardId != null) request.fields['ward_id'] = wardId.toString();
      if (about != null && about.isNotEmpty) request.fields['about'] = about;

      // Add logo
      if (logo != null) {
        final mimeType = lookupMimeType(logo.path) ?? 'image/png';
        request.files.add(await http.MultipartFile.fromPath(
          'logo',
          logo.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isAgencyRegistered = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Agency registration failed: ${response.body}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to register agency: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BROWSE PROFILES (Only opposite sex for individuals, all for agencies)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> getAllProfiles({
    String? gender,
    int? minAge,
    int? maxAge,
    String? location,
  }) async {
    _setLoading(true);
    try {
      final params = <String, dynamic>{};
      if (gender != null && gender.isNotEmpty) params['gender'] = gender;
      if (minAge != null) params['min_age'] = minAge;
      if (maxAge != null) params['max_age'] = maxAge;
      if (location != null && location.isNotEmpty) params['location'] = location;

      final response = await _apiService.get('/matrimonial/users', queryParameters: params);
      
      if (response != null) {
        final list = response is List ? response : [];
        _profiles = list.map((j) => MatrimonialProfile.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load profiles: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<MatrimonialProfile?> getProfileById(int id) async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/matrimonial/users/$id');
      if (response != null && response['profile'] != null) {
        _currentProfile = MatrimonialProfile.fromJson(response['profile']);
        notifyListeners();
        return _currentProfile;
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AGENCY LISTINGS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> getAllAgencies({String? location}) async {
    _setLoading(true);
    try {
      final params = <String, dynamic>{};
      if (location != null && location.isNotEmpty) params['location'] = location;

      final response = await _apiService.get('/matrimonial/agencies', queryParameters: params);
      
      if (response != null) {
        final list = response is List ? response : [];
        _agencies = list.map((j) => MatrimonialAgency.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load agencies: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MATCHES / INTERESTS
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> sendInterest(int receiverId, {String? message}) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/matrimonial/matches', data: {
        'receiver_id': receiverId,
        'message': message ?? 'I am interested in connecting with you',
      });
      return response != null && response['id'] != null;
    } catch (e) {
      _errorMessage = 'Failed to send interest: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getMyMatches({String? status}) async {
    _setLoading(true);
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'ALL') {
        params['status_filter'] = status;
      }
      
      final response = await _apiService.get('/matrimonial/my-matches', queryParameters: params);
      
      if (response != null && response['success'] == true) {
        final matchesList = response['matches'] as List? ?? [];
        _myMatches = matchesList.map((j) => MatchRequest.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load matches: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UPDATE MATCH STATUS (Accept/Reject)
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> updateMatchStatus(int matchId, String status) async {
    _setLoading(true);
    try {
      final response = await _apiService.put('/matrimonial/matches/$matchId/status?status=$status');
      if (response != null && response['success'] == true) {
        // Refresh matches after update
        await getMyMatches();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update match status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DASHBOARD STATS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> getDashboardStats() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/matrimonial/dashboard-stats');
      if (response != null && response['success'] == true) {
        _totalProfiles = response['total_individuals'] ?? 0;
        _totalAgencies = response['total_agencies'] ?? 0;
        _isRegistered = response['is_registered'] ?? false;
        
        if (response['recent_profiles'] != null) {
          _recentProfiles = (response['recent_profiles'] as List)
              .whereType<Map<String, dynamic>>()
              .map((j) => MatrimonialProfile.fromJson(j))
              .toList();
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load dashboard stats: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UTILITY METHODS
  // ───────────────────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _profiles = [];
    _recentProfiles = [];
    _myMatches = [];
    _agencies = [];
    _currentProfile = null;
    _currentAgency = null;
    _isLoading = false;
    _isRegistered = false;
    _isAgencyRegistered = false;
    _totalProfiles = 0;
    _totalAgencies = 0;
    _errorMessage = null;
    notifyListeners();
  }
}