// 首页视频列表项模型
class VideoItem {
  final String id;           // 视频ID，用于请求详情
  final String title;        // 标题
  final String cover;        // 封面图
  final String? score;       // 评分
  final String? year;        // 年份
  final String? area;        // 地区
  final String? actors;      // 主演
  final String? description; // 简介
  final int cat;             // 分类: 1电影 2电视剧 3综艺 4动漫

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
}

// 剧集/播放源信息
class VideoSource {
  final String name;          // 源名称（如：腾讯视频）
  final List<Episode> episodes; // 剧集列表

  VideoSource({required this.name, required this.episodes});
}

// 单集信息
class Episode {
  final String title; // 第X集
  final String url;   // 视频页面URL

  Episode({required this.title, required this.url});
}
