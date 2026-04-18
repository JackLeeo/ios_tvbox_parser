class SearchResult {
  final String title;
  final String cover;
  final String url;
  final String platform;
  List<Episode> episodes = [];
  bool isEpisodesLoaded = false;

  SearchResult({
    required this.title,
    required this.cover,
    required this.url,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'cover': cover,
    'url': url,
    'platform': platform,
  };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title'],
    cover: json['cover'],
    url: json['url'],
    platform: json['platform'],
  );
}

class Episode {
  final String title;
  final String url;
  final int number;

  Episode({
    required this.title,
    required this.url,
    required this.number,
  });
}