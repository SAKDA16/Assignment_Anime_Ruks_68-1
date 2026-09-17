class EpisodeModel {
  final String id;
  final int episode;
  final String title;
  final String videoUrl;

  EpisodeModel({
    required this.id,
    required this.episode,
    required this.title,
    required this.videoUrl,
  });

  factory EpisodeModel.fromMap(String id, Map<String, dynamic> data) {
    return EpisodeModel(
      id: id,
      episode: _toInt(data['episode']),
      title: data['title']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'episode': episode, 'title': title, 'videoUrl': videoUrl};
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }
}
