class AnimeModel {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String description;
  final String type;
  final int latestEpisode;
  final double rating;
  final bool isFeatured;
  final bool isFavorite;

  AnimeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.type,
    required this.latestEpisode,
    required this.rating,
    required this.isFeatured,
    required this.isFavorite,
  });

  factory AnimeModel.fromMap(String id, Map<String, dynamic> data) {
    return AnimeModel(
      id: id,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      latestEpisode: _toInt(data['latestEpisode']),
      rating: _toDouble(data['rating']),
      isFeatured: data['isFeatured'] == true,
      isFavorite: data['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'type': type,
      'latestEpisode': latestEpisode,
      'rating': rating,
      'isFeatured': isFeatured,
      'isFavorite': isFavorite,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
