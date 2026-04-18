class VideoItem {
  final String id;
  final String title;
  final String cover;
  final String? desc;
  final String? year;
  final String? area;
  final String? actors;
  final int cat; // 1电影 2电视剧 3综艺 4动漫

  VideoItem({required this.id, required this.title, required this.cover, this.desc, this.year, this.area, this.actors, required this.cat});

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['vod_id']?.toString() ?? '',
      title: json['vod_name'] ?? '',
      cover: json['vod_pic'] ?? '',
      desc: json['vod_content'],
      year: json['vod_year'],
      area: json['vod_area'],
      actors: json['vod_actor'],
      cat: int.tryParse(json['type_id']?.toString() ?? '0') ?? 0,
    );
  }
}

class VideoDetail {
  final VideoItem info;
  final List<Episode> episodes;

  VideoDetail({required this.info, required this.episodes});
}

class Episode {
  final String name;
  final String url;

  Episode({required this.name, required this.url});
}
