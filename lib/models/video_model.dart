class VideoItem {
  final String id;
  final String title;
  final String cover;
  final String? score;
  final String? year;
  final String? area;
  final String? actors;
  final String? description;
  final int cat; // 1电影 2电视剧 3综艺 4动漫

  VideoItem({
    required this.id,
    required this.title,
    required this.cover,
    this.score,
    this.year,
    this.area,
    this.actors,
    this.description,
    required this.cat,
  });

  // 从 JSON 转换为对象
  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      score: json['score']?.toString(),
      year: json['year']?.toString(),
      area: json['area']?.toString(),
      actors: json['actor']?.toString(),
      description: json['description']?.toString(),
      cat: json['cat'] ?? 0,
    );
  }

  // 从对象转换为 JSON（收藏功能必需）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover': cover,
      'score': score,
      'year': year,
      'area': area,
      'actor': actors,
      'description': description,
      'cat': cat,
    };
  }
}

class VideoSource {
  final String name;
  final List<Episode> episodes;

  VideoSource({required this.name, required this.episodes});
}

class Episode {
  final String title;
  final String url;

  Episode({required this.title, required this.url});
}
