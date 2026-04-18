class PlayHistory {
  final String title;
  final String cover;
  final String videoUrl;
  final String platform;
  final int lastEpisodeIndex;
  final int playProgressSeconds;
  final DateTime watchTime;

  PlayHistory({
    required this.title,
    required this.cover,
    required this.videoUrl,
    required this.platform,
    required this.lastEpisodeIndex,
    required this.playProgressSeconds,
    required this.watchTime,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'cover': cover,
    'videoUrl': videoUrl,
    'platform': platform,
    'lastEpisodeIndex': lastEpisodeIndex,
    'playProgressSeconds': playProgressSeconds,
    'watchTime': watchTime.millisecondsSinceEpoch,
  };

  factory PlayHistory.fromJson(Map<String, dynamic> json) => PlayHistory(
    title: json['title'],
    cover: json['cover'],
    videoUrl: json['videoUrl'],
    platform: json['platform'],
    lastEpisodeIndex: json['lastEpisodeIndex'],
    playProgressSeconds: json['playProgressSeconds'],
    watchTime: DateTime.fromMillisecondsSinceEpoch(json['watchTime']),
  );
}