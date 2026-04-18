import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/source.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 11; SM-G9910) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.210 Mobile Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9',
      'Referer': 'https://www.baidu.com/',
    },
  ));

  /// 智能构建请求 URL（自动处理完整 URL 或拼接）
  String _buildUrl(SiteRule site, String path) {
    final api = site.api.trim();
    // 如果 api 已经是完整 http(s) URL，直接替换末尾或追加
    if (api.startsWith('http://') || api.startsWith('https://')) {
      // 若 api 以 / 结尾，直接拼接
      if (api.endsWith('/')) {
        return '$api$path';
      }
      // 若 api 包含查询参数，使用 & 连接
      if (api.contains('?')) {
        return '$api&$path';
      }
      return '$api?$path';
    }
    // 否则假定为域名，补全协议
    return 'https://$api?$path';
  }

  Future<List<VideoItem>> getHomeList(SiteRule site, {int page = 1}) async {
    try {
      final url = _buildUrl(site, 'ac=videolist&pg=$page');
      print('请求首页: $url');
      final response = await _dio.get(
        url,
        options: Options(headers: site.headers),
      );
      print('响应状态: ${response.statusCode}');
      print('响应数据: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data;
        // 兼容不同返回格式
        if (data is Map<String, dynamic>) {
          if (data['code'] == 1 || data['code'] == 200) {
            final list = data['list'] ?? data['data'] ?? [];
            if (list is List) {
              return list.map((e) => VideoItem.fromJson(e)).toList();
            }
          }
        }
      }
      return [];
    } catch (e) {
      print('首页请求异常: $e');
      return [];
    }
  }

  Future<List<VideoItem>> search(SiteRule site, String keyword) async {
    try {
      final url = site.searchUrl != null && site.searchUrl!.isNotEmpty
          ? site.searchUrl!.replaceAll('{keyword}', Uri.encodeComponent(keyword))
          : _buildUrl(site, 'ac=videolist&wd=${Uri.encodeComponent(keyword)}');
      print('搜索请求: $url');
      final response = await _dio.get(
        url,
        options: Options(headers: site.headers),
      );
      print('搜索响应: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['code'] == 1 || data['code'] == 200) {
            final list = data['list'] ?? data['data'] ?? [];
            if (list is List) {
              return list.map((e) => VideoItem.fromJson(e)).toList();
            }
          }
        }
      }
      return [];
    } catch (e) {
      print('搜索异常: $e');
      return [];
    }
  }

  Future<List<Episode>> getEpisodes(SiteRule site, String videoId) async {
    try {
      final url = _buildUrl(site, 'ac=videolist&ids=$videoId');
      print('获取剧集: $url');
      final response = await _dio.get(
        url,
        options: Options(headers: site.headers),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['code'] == 1 || data['code'] == 200) {
            final list = data['list'];
            if (list is List && list.isNotEmpty) {
              final vod = list[0];
              // 处理剧集列表
              final episodes = <Episode>[];
              // 1. 尝试 vod_play_list
              if (vod['vod_play_list'] is Map) {
                final playList = vod['vod_play_list'] as Map;
                playList.forEach((source, urls) {
                  if (urls is String) {
                    final parts = urls.split('#');
                    for (var part in parts) {
                      final pair = part.split('\$');
                      if (pair.length == 2) {
                        episodes.add(Episode(name: pair[0], url: pair[1]));
                      }
                    }
                  }
                });
              }
              // 2. 尝试 vod_play_url
              if (episodes.isEmpty && vod['vod_play_url'] is String) {
                final urls = vod['vod_play_url'].split('#');
                for (var part in urls) {
                  final pair = part.split('\$');
                  if (pair.length == 2) {
                    episodes.add(Episode(name: pair[0], url: pair[1]));
                  }
                }
              }
              return episodes;
            }
          }
        }
      }
      return [];
    } catch (e) {
      print('剧集异常: $e');
      return [];
    }
  }
}
