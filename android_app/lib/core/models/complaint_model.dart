class Complaint {
  final int id;
  final int citizenId;
  final String citizenName;
  final int wardId;
  final String wardName;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String address;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? resolvedNotes;

  Complaint({
    required this.id,
    required this.citizenId,
    required this.citizenName,
    required this.wardId,
    required this.wardName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.address,
    required this.createdAt,
    this.updatedAt,
    this.resolvedNotes,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      citizenId: json['citizen_id'] as int,
      citizenName: json['citizen_name'] as String? ?? 'Unknown',
      wardId: json['ward_id'] as int,
      wardName: json['ward_name'] as String? ?? 'Unknown',
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String? ?? 'Not provided',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      resolvedNotes: json['resolved_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizen_id': citizenId,
      'citizen_name': citizenName,
      'ward_id': wardId,
      'ward_name': wardName,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_notes': resolvedNotes,
    };
  }

  String getStatusDisplay() {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }
}
