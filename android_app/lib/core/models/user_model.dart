class User {
  final int id;
  final String name;
  final String? email;  // ✅ Made nullable to match backend
  final String mobile;  // ✅ Changed from 'phone' to 'mobile'
  final String role;
  final int wardId;     // ✅ Made non-nullable as it's always present
  final String? wardName;
  final String address; // ✅ Added address field
  final String? profileImage; // ✅ Added profile_image field
  final bool isActive;
  final bool isVerified; // ✅ Added is_verified field
  final DateTime? createdAt; // ✅ Made nullable for safety

  User({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    required this.role,
    required this.wardId,
    this.wardName,
    required this.address,
    this.profileImage,
    required this.isActive,
    required this.isVerified,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,  // ✅ Nullable
      mobile: json['mobile'] as String, // ✅ Changed from 'phone'
      role: json['role'] as String,
      wardId: json['ward_id'] as int,   // ✅ Non-nullable
      wardName: json['ward_name'] as String?,
      address: json['address'] as String? ?? '', // ✅ Default to empty string
      profileImage: json['profile_image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,  // ✅ Changed from 'phone'
      'role': role,
      'ward_id': wardId,
      'ward_name': wardName,
      'address': address,
      'profile_image': profileImage,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? mobile,
    String? role,
    int? wardId,
    String? wardName,
    String? address,
    String? profileImage,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      wardId: wardId ?? this.wardId,
      wardName: wardName ?? this.wardName,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getter for display
  String get displayMobile => mobile;

  // Helper getter for email display
  String get displayEmail => email ?? 'No email';
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}