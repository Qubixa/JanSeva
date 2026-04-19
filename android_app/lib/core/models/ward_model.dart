class Ward {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  Ward({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }

  @override
  String toString() => name;
}
