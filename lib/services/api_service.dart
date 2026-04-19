import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/source.dart';
import 'node_parser_service.dart';
import 'log_service.dart';

class ApiService {
  final NodeParserService _parser = NodeParserService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final LogService _log = LogService();

  Future<List<VideoItem>> getHomeList(SiteRule site, {int page = 1}) async {
    _log.add('开始获取首页数据：站点=${site.name}, page=$page');
    try {
      final rule = site.ext?['rule'] ?? site.api;
      _log.add('使用规则: $rule');
      final result = await _parser.getHome(rule, page: page);
      _log.add('Node.js 返回: ${result.toString().substring(0, 200)}...');
      final list = result['data']['list'] as List? ?? [];
      _log.add('解析到 ${list.length} 条影片');
      return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _log.add('Node.js 解析失败: $e，回退到公共API');
      return await _fallbackHome(site, page);
    }
  }

  Future<List<VideoItem>> _fallbackHome(SiteRule site, int page) async {
    try {
      final url = _buildUrl(site, 'ac=videolist&pg=$page');
      _log.add('请求公共API: $url');
      final response = await _dio.get(url, options: Options(headers: site.headers));
      _log.add('响应状态: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        _log.add('响应数据: ${data.toString().substring(0, 200)}...');
        if (data is Map && (data['code'] == 1 || data['code'] == 200)) {
          final list = data['list'] ?? data['data'] ?? [];
          if (list is List) {
            _log.add('解析到 ${list.length} 条影片');
            return list.map((e) => VideoItem.fromJson(e)).toList();
          }
        }
      }
      _log.add('未找到影片数据');
      return [];
    } catch (e) {
      _log.add('公共API请求失败: $e');
      return [];
    }
  }

  Future<List<VideoItem>> search(SiteRule site, String keyword, {int page = 1}) async {
    _log.add('开始搜索：站点=${site.name}, 关键词=$keyword');
    try {
      final rule = site.ext?['rule'] ?? site.api;
      final result = await _parser.search(rule, keyword, page: page);
      final list = result['data']['list'] as List? ?? [];
      _log.add('搜索到 ${list.length} 条结果');
      return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _log.add('Node.js 搜索失败: $e，回退公共API');
      return await _fallbackSearch(site, keyword, page);
    }
  }

  Future<List<VideoItem>> _fallbackSearch(SiteRule site, String keyword, int page) async {
    try {
      final url = site.searchUrl != null && site.searchUrl!.isNotEmpty
          ? site.searchUrl!.replaceAll('{keyword}', Uri.encodeComponent(keyword))
          : _buildUrl(site, 'ac=videolist&wd=${Uri.encodeComponent(keyword)}');
      _log.add('请求公共搜索API: $url');
      final response = await _dio.get(url, options: Options(headers: site.headers));
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && (data['code'] == 1 || data['code'] == 200)) {
          final list = data['list'] ?? data['data'] ?? [];
          if (list is List) {
            _log.add('搜索到 ${list.length} 条结果');
            return list.map((e) => VideoItem.fromJson(e)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      _log.add('公共搜索API失败: $e');
      return [];
    }
  }

  Future<List<Episode>> getEpisodes(SiteRule site, String videoId) async {
    _log.add('获取剧集：videoId=$videoId');
    try {
      final rule = site.ext?['rule'] ?? site.api;
      final result = await _parser.getDetail(rule, videoId);
      return _parseEpisodes(result['data']);
    } catch (e) {
      _log.add('Node.js 获取剧集失败: $e，回退公共API');
      return await _fallbackEpisodes(site, videoId);
    }
  }

  Future<List<Episode>> _fallbackEpisodes(SiteRule site, String videoId) async {
    try {
      final url = _buildUrl(site, 'ac=videolist&ids=$videoId');
      _log.add('请求公共剧集API: $url');
      final response = await _dio.get(url, options: Options(headers: site.headers));
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && (data['code'] == 1 || data['code'] == 200)) {
          return _parseEpisodes(data);
        }
      }
      return [];
    } catch (e) {
      _log.add('公共剧集API失败: $e');
      return [];
    }
  }

  List<Episode> _parseEpisodes(Map<String, dynamic> data) {
    final episodes = <Episode>[];
    if (data['list'] != null && (data['list'] as List).isNotEmpty) {
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
    _log.add('解析到 ${episodes.length} 集');
    return episodes;
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

  String _buildUrl(SiteRule site, String path) {
    String api = site.api;
    if (!api.startsWith('http')) {
      api = 'https://$api';
    }
    if (api.endsWith('/')) {
      return '$api$path';
    }
    if (api.contains('?')) {
      return '$api&$path';
    }
    return '$api?$path';
  }
}
