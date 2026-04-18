import 'package:dio/dio.dart';
import '../models/video_model.dart';

class VideoApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.web.360kan.com/v1',
    connectTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': 'Mozilla/5.0'},
  ));

  /// 获取首页推荐/分类数据
  /// type: 'hot'=热播, 'new'=最新, 'rank'=排行榜
  /// cat: 1=电影, 2=电视剧, 3=综艺, 4=动漫
  Future<List<VideoItem>> getVideoList({
    required int cat,
    String type = 'hot',
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get('/filter/list', queryParameters: {
        'catid': cat,
        'rank': type == 'hot' ? 'rankhot' : (type == 'new' ? 'ranklatest' : 'rankpoint'),
        'pageno': page,
        'size': size,
      });
      
      if (response.data['code'] == 200 && response.data['data'] != null) {
        final List list = response.data['data']['list'] ?? [];
        return list.map((json) => VideoItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('获取视频列表失败: $e');
      return [];
    }
  }

  /// 搜索视频
  /// 使用 360 搜索接口，更稳定可靠
  Future<List<VideoItem>> searchVideo(String keyword, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'https://api.so.360kan.com/index',
        queryParameters: {
          'force_v': '1',
          'kw': keyword,
          'pageno': page,
          'v_ap': '1',
          'tab': 'all',
        },
      );
      
      // 解析搜索结果
      if (response.data['code'] == 200 && response.data['data'] != null) {
        final List list = response.data['data']['list'] ?? [];
        return list.map((json) => VideoItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('搜索失败: $e');
      return [];
    }
  }

  /// 获取视频详情（包含剧集信息）
  Future<Map<String, dynamic>?> getVideoDetail(String videoId, {int cat = 2}) async {
    try {
      final response = await _dio.get('/detail', queryParameters: {
        'cat': cat,
        'id': videoId,
      });
      
      if (response.data['code'] == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('获取详情失败: $e');
      return null;
    }
  }

  /// 解析剧集列表
  List<VideoSource> parseVideoSources(Map<String, dynamic> detailData) {
    final List<VideoSource> sources = [];
    final sourcesData = detailData['sources'];
    
    if (sourcesData != null && sourcesData is List) {
      for (var sourceJson in sourcesData) {
        final List<Episode> episodes = [];
        final playList = sourceJson['playlist'] ?? [];
        
        for (var ep in playList) {
          episodes.add(Episode(
            title: ep['title'] ?? '',
            url: ep['url'] ?? '',
          ));
        }
        
        if (episodes.isNotEmpty) {
          sources.add(VideoSource(
            name: sourceJson['name'] ?? '未知源',
            episodes: episodes,
          ));
        }
      }
    }
    
    return sources;
  }
}
