import 'package:dio/dio.dart';
import '../models/video_model.dart';

class VideoApiService {
  // 使用豆瓣 API 的第三方镜像（稳定、无需翻墙）
  static const String _baseUrl = 'https://frodo.douban.com/api/v2';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Mozilla/5.0',
      'Referer': 'https://movie.douban.com/',
    },
  ));

  /// 获取首页推荐（根据分类）
  /// cat: 1=电影 2=电视剧 3=综艺(用电影代替) 4=动漫(用电影代替)
  Future<List<VideoItem>> getVideoList({
    required int cat,
    String type = 'hot',
    int page = 1,
    int size = 20,
  }) async {
    try {
      // 豆瓣 API 的分类参数
      String apiPath = '/movie/';
      Map<String, dynamic> queryParams = {
        'start': (page - 1) * size,
        'count': size,
        'apiKey': '0b2bdeda43b5688921839c8ecb20399b', // 豆瓣官方测试 key
      };

      // 根据分类选择接口
      if (cat == 1) {
        // 电影：热映 / 即将上映
        apiPath = type == 'hot' ? '/movie/in_theaters' : '/movie/coming_soon';
      } else if (cat == 2) {
        // 电视剧：豆瓣没有直接分类，用电影榜单代替
        apiPath = '/movie/top250';
      } else {
        // 综艺/动漫：用电影代替
        apiPath = '/movie/top250';
      }

      final response = await _dio.get(apiPath, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List subjects = response.data['subjects'] ?? [];
        return subjects.map((json) => _parseDoubanSubject(json, cat)).toList();
      }
      return [];
    } catch (e) {
      print('获取列表失败: $e');
      return [];
    }
  }

  /// 搜索视频
  Future<List<VideoItem>> searchVideo(String keyword, {int page = 1}) async {
    try {
      final response = await _dio.get('/search/movie', queryParameters: {
        'q': keyword,
        'start': (page - 1) * 20,
        'count': 20,
        'apiKey': '0b2bdeda43b5688921839c8ecb20399b',
      });

      if (response.statusCode == 200) {
        final List subjects = response.data['subjects'] ?? [];
        return subjects.map((json) => _parseDoubanSubject(json, 1)).toList();
      }
      return [];
    } catch (e) {
      print('搜索失败: $e');
      return [];
    }
  }

  /// 获取视频详情（豆瓣 API 不直接提供播放地址，需要额外解析）
  Future<Map<String, dynamic>?> getVideoDetail(String videoId, {int cat = 1}) async {
    try {
      final response = await _dio.get('/movie/$videoId', queryParameters: {
        'apiKey': '0b2bdeda43b5688921839c8ecb20399b',
      });

      if (response.statusCode == 200) {
        // 构造与之前兼容的详情数据结构
        return {
          'id': videoId,
          'title': response.data['title'],
          'cover': response.data['images']['large'],
          'summary': response.data['summary'],
          'year': response.data['year'],
          'rating': response.data['rating']['average'].toString(),
          // 播放源：豆瓣没有直接播放链接，这里留空，后续通过解析接口处理
          'sources': [],
        };
      }
      return null;
    } catch (e) {
      print('获取详情失败: $e');
      return null;
    }
  }

  /// 解析豆瓣数据为 VideoItem
  VideoItem _parseDoubanSubject(Map<String, dynamic> json, int cat) {
    return VideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      cover: json['images']['large'] ?? '',
      score: json['rating']['average']?.toString(),
      year: json['year']?.toString(),
      area: null,
      actors: null,
      description: null,
      cat: cat,
    );
  }

  /// 解析剧集列表（豆瓣电影没有剧集，返回空，播放时直接用解析接口解析豆瓣详情页）
  List<VideoSource> parseVideoSources(Map<String, dynamic> detailData) {
    // 由于豆瓣不提供直接播放源，我们将豆瓣详情页 URL 作为唯一“剧集”
    // 播放器拿到这个 URL 后会通过解析接口解析
    final videoUrl = 'https://movie.douban.com/subject/${detailData['id']}/';
    return [
      VideoSource(
        name: '豆瓣',
        episodes: [
          Episode(
            title: detailData['title'] ?? '正片',
            url: videoUrl,
          )
        ],
      )
    ];
  }
}
