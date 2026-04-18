import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/source.dart';
import 'node_parser_service.dart';

class ApiService {
  final NodeParserService _parser = NodeParserService();
  final Dio _dio = Dio();

  Future<List<VideoItem>> getHomeList(SiteRule site, {int page = 1}) async {
    try {
      final rule = site.ext?['rule'] ?? site.api;
      final result = await _parser.getHome(rule, page: page);
      final list = result['data']['list'] as List? ?? [];
      return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('获取首页失败: $e');
      return [];
    }
  }

  Future<List<VideoItem>> search(SiteRule site, String keyword, {int page = 1}) async {
    try {
      final rule = site.ext?['rule'] ?? site.api;
      final result = await _parser.search(rule, keyword, page: page);
      final list = result['data']['list'] as List? ?? [];
      return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('搜索失败: $e');
      return [];
    }
  }

  Future<List<Episode>> getEpisodes(SiteRule site, String videoId) async {
    try {
      final rule = site.ext?['rule'] ?? site.api;
      final result = await _parser.getDetail(rule, videoId);
      final data = result['data'];
      final episodes = <Episode>[];

      if (data != null && data['list'] != null && (data['list'] as List).isNotEmpty) {
        final vod = (data['list'] as List).first;
        if (vod['vod_play_list'] is Map) {
          final playList = vod['vod_play_list'] as Map;
          playList.forEach((source, urls) {
            if (urls is String) {
              for (var part in urls.split('#')) {
                final pair = part.split('\$');
                if (pair.length == 2) {
                  episodes.add(Episode(name: pair[0], url: pair[1]));
                }
              }
            }
          });
        }
        if (episodes.isEmpty && vod['vod_play_url'] is String) {
          for (var part in vod['vod_play_url'].split('#')) {
            final pair = part.split('\$');
            if (pair.length == 2) {
              episodes.add(Episode(name: pair[0], url: pair[1]));
            }
          }
        }
      }
      return episodes;
    } catch (e) {
      print('获取剧集失败: $e');
      return [];
    }
  }

  Future<String> getPlayUrl(SiteRule site, String flag, String id) async {
    try {
      final rule = site.ext?['rule'] ?? site.api;
      final result = await _parser.getPlayUrl(rule, flag, id);
      return result['data']['url'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
