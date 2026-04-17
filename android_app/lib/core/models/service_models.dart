class EmergencyService {
  final int id;
  final String name;
  final String type;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? category;
  final int? wardId;
  final String? wardName;
  final double? latitude;
  final double? longitude;
  final String address;
  final String? googleMapsLink;
  final bool isActive;
  final String? isCitywide;
  final String? is24x7;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.category,
    this.wardId,
    this.wardName,
    this.latitude,
    this.longitude,
    required this.address,
    this.googleMapsLink,
    required this.isActive,
    this.isCitywide,
    this.is24x7,
    required this.createdAt,
    this.updatedAt,
  });

  factory EmergencyService.fromJson(Map<String, dynamic> json) {
    return EmergencyService(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      phone: json['phone'] as String? ?? '',
      alternatePhone: json['alternate_phone'] as String?,
      email: json['email'] as String?,
      category: json['category'] as String?,
      wardId: json['ward_id'] as int?,
      wardName: json['ward_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String? ?? '',
      googleMapsLink: json['google_maps_link'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 'Y',
      // Handle both boolean and string for is_citywide
      isCitywide: json['is_citywide'] is bool
          ? (json['is_citywide'] == true ? 'Y' : 'N')
          : json['is_citywide'] as String?,
      // Handle both boolean and string for is_24x7
      is24x7: json['is_24x7'] is bool
          ? (json['is_24x7'] == true ? 'Y' : 'N')
          : json['is_24x7'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'category': category,
      'ward_id': wardId,
      'ward_name': wardName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'google_maps_link': googleMapsLink,
      'is_active': isActive,
      'is_citywide': isCitywide,
      'is_24x7': is24x7,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Add a getter for description if needed by the UI
  String get description => category ?? type;
}

class Scheme {
  final int id;
  final String name;
  final String description;
  final String category;  // ADD THIS LINE
  final String? benefitsDescription;
  final String? eligibility;
  final String? applicationProcess;
  final String? contactInfo;
  final DateTime? lastUpdated;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    required this.category,  // ADD THIS LINE
    this.benefitsDescription,
    this.eligibility,
    this.applicationProcess,
    this.contactInfo,
    this.lastUpdated,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,  // ADD THIS LINE
      benefitsDescription: json['benefits_description'] as String?,
      eligibility: json['eligibility'] as String?,
      applicationProcess: json['application_process'] as String?,
      contactInfo: json['contact_info'] as String?,
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated'] as String) : null,
    );
  }
}

class TransportInfo {
  final int id;
  final String transportType;
  final String name;
  final String? routeNumber;
  final String source;
  final String destination;
  final String? viaStops;
  final String? departureTime;
  final String? arrivalTime;
  final String? frequency;
  final String? fare;
  final String? mapLink;
  final bool isActive;
  final DateTime createdAt;

  TransportInfo({
    required this.id,
    required this.transportType,
    required this.name,
    this.routeNumber,
    required this.source,
    required this.destination,
    this.viaStops,
    this.departureTime,
    this.arrivalTime,
    this.frequency,
    this.fare,
    this.mapLink,
    required this.isActive,
    required this.createdAt,
  });

  factory TransportInfo.fromJson(Map<String, dynamic> json) {
    return TransportInfo(
      id: json['id'] as int,
      transportType: json['transport_type'] as String,
      name: json['name'] as String,
      routeNumber: json['route_number']?.toString(),
      source: json['source'] as String,
      destination: json['destination'] as String,
      viaStops: json['via_stops'] as String?,
      departureTime: json['departure_time'] as String?,
      arrivalTime: json['arrival_time'] as String?,
      frequency: json['frequency'] as String?,
      fare: json['fare'] as String?,
      mapLink: json['map_link'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 'Y',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transport_type': transportType,
      'name': name,
      'route_number': routeNumber,
      'source': source,
      'destination': destination,
      'via_stops': viaStops,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'frequency': frequency,
      'fare': fare,
      'map_link': mapLink,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Contact {
  final int id;
  final String name;
  final String department;
  final String phone;
  final String? email;
  final String? address;
  final String? website;

  Contact({
    required this.id,
    required this.name,
    required this.department,
    required this.phone,
    this.email,
    this.address,
    this.website,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int,
      name: json['name'] as String,
      department: json['department'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'phone': phone,
      'email': email,
      'address': address,
      'website': website,
    };
  }
}
