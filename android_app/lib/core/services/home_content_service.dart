import 'api_service.dart';

class HomeContentItem {
  final String id;
  final String contentType;
  final String title;
  final String description;
  final String? imageUrl;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  HomeContentItem({
    required this.id,
    required this.contentType,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.order,
    required this.isActive,
    required this.createdAt,
  });

  factory HomeContentItem.fromJson(Map<String, dynamic> json) {
    return HomeContentItem(
      id: json['id'] ?? '',
      contentType: json['content_type'] ?? 'banner',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class HomeContentService {
  final ApiService _apiService;

  HomeContentService(this._apiService);

  Future<List<HomeContentItem>> fetchHomeContent() async {
    try {
      final response = await _apiService.get('/public/home-content');
      if (response is List) {
        return response
            .map((item) => HomeContentItem.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch home content: $e');
    }
  }

  Future<HomeContentItem?> fetchContentById(String id) async {
    try {
      final response = await _apiService.get('/public/home-content/$id');
      if (response is Map) {
        return HomeContentItem.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch content: $e');
    }
  }

  List<HomeContentItem> filterByType(List<HomeContentItem> items, String type) {
    return items.where((item) => item.contentType == type).toList();
  }
}
