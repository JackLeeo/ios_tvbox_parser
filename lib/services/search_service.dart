import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import '../models/search_result.dart';
import '../utils/constants.dart';

class SearchService {
  final Dio _dio = Dio(BaseOptions(
    headers: {
      "User-Agent": AppConstants.userAgent,
      "Accept-Language": "zh-CN,zh;q=0.9",
    },
    followRedirects: true,
  ));

  Future<List<SearchResult>> searchVideo(String keyword) async {
    final List<SearchResult> results = [];
    await Future.wait([
      _searchTencent(keyword, results),
      _searchIqiyi(keyword, results),
      _searchYouku(keyword, results),
      _searchMgtv(keyword, results),
    ]);
    return results;
  }

  Future<void> loadEpisodes(SearchResult result) async {
    if (result.isEpisodesLoaded) return;

    try {
      final response = await _dio.get(result.url);
      switch (result.platform) {
        case '腾讯视频':
          await _parseTencentEpisodes(response.data, result);
          break;
        case '爱奇艺':
          await _parseIqiyiEpisodes(response.data, result);
          break;
        case '优酷':
          await _parseYoukuEpisodes(response.data, result);
          break;
        case '芒果TV':
          await _parseMgtvEpisodes(response.data, result);
          break;
      }
      result.isEpisodesLoaded = true;
    } catch (e) {
      print('解析剧集失败: $e');
    }
  }

  Future<void> _searchTencent(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get("https://v.qq.com/x/search/?q=$keyword");
      final document = parser.parse(response.data);
      final items = document.querySelectorAll('.result_item_v');

      for (final item in items.take(6)) {
        final title = item.querySelector('.result_title')?.text.trim() ?? '';
        final cover = item.querySelector('img')?.attributes['src'] ?? '';
        final link = item.querySelector('a')?.attributes['href'] ?? '';

        if (title.isNotEmpty && link.contains('v.qq.com')) {
          results.add(SearchResult(
            title: title,
            cover: cover.startsWith('//') ? 'https:$cover' : cover,
            url: link.startsWith('http') ? link : 'https:$link',
            platform: '腾讯视频',
          ));
        }
      }
    } catch (e) {
      print('腾讯搜索失败: $e');
    }
  }

  Future<void> _parseTencentEpisodes(String html, SearchResult result) async {
    final document = parser.parse(html);
    final episodeItems = document.querySelectorAll('.episode-item a');

    for (int i = 0; i < episodeItems.length; i++) {
      final item = episodeItems[i];
      final title = item.text.trim();
      final url = item.attributes['href'] ?? '';

      if (url.isNotEmpty) {
        result.episodes.add(Episode(
          title: title.isEmpty ? '第${i+1}集' : title,
          url: url.startsWith('http') ? url : 'https:$url',
          number: i+1,
        ));
      }
    }
  }

  Future<void> _searchIqiyi(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get("https://www.iqiyi.com/search/$keyword.html");
      final document = parser.parse(response.data);
      final items = document.querySelectorAll('.qy-search-result-item');

      for (final item in items.take(6)) {
        final title = item.querySelector('.qy-search-result-title')?.text.trim() ?? '';
        final cover = item.querySelector('img')?.attributes['src'] ?? '';
        final link = item.querySelector('a')?.attributes['href'] ?? '';

        if (title.isNotEmpty && link.contains('iqiyi.com')) {
          results.add(SearchResult(
            title: title,
            cover: cover.startsWith('//') ? 'https:$cover' : cover,
            url: link.startsWith('http') ? link : 'https:$link',
            platform: '爱奇艺',
          ));
        }
      }
    } catch (e) {
      print('爱奇艺搜索失败: $e');
    }
  }

  Future<void> _parseIqiyiEpisodes(String html, SearchResult result) async {
    final document = parser.parse(html);
    final episodeItems = document.querySelectorAll('.album-play-item a');

    for (int i = 0; i < episodeItems.length; i++) {
      final item = episodeItems[i];
      final title = item.text.trim();
      final url = item.attributes['href'] ?? '';

      if (url.isNotEmpty) {
        result.episodes.add(Episode(
          title: title.isEmpty ? '第${i+1}集' : title,
          url: url.startsWith('http') ? url : 'https:$url',
          number: i+1,
        ));
      }
    }
  }

  Future<void> _searchYouku(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get("https://so.youku.com/search_video/q_$keyword");
      final document = parser.parse(response.data);
      final items = document.querySelectorAll('.so-result-item');

      for (final item in items.take(6)) {
        final title = item.querySelector('.so-title')?.text.trim() ?? '';
        final cover = item.querySelector('img')?.attributes['src'] ?? '';
        final link = item.querySelector('a')?.attributes['href'] ?? '';

        if (title.isNotEmpty && link.contains('youku.com')) {
          results.add(SearchResult(
            title: title,
            cover: cover.startsWith('//') ? 'https:$cover' : cover,
            url: link.startsWith('http') ? link : 'https:$link',
            platform: '优酷',
          ));
        }
      }
    } catch (e) {
      print('优酷搜索失败: $e');
    }
  }

  Future<void> _parseYoukuEpisodes(String html, SearchResult result) async {
    final document = parser.parse(html);
    final episodeItems = document.querySelectorAll('.anthology-list-item a');

    for (int i = 0; i < episodeItems.length; i++) {
      final item = episodeItems[i];
      final title = item.text.trim();
      final url = item.attributes['href'] ?? '';

      if (url.isNotEmpty) {
        result.episodes.add(Episode(
          title: title.isEmpty ? '第${i+1}集' : title,
          url: url.startsWith('http') ? url : 'https:$url',
          number: i+1,
        ));
      }
    }
  }

  Future<void> _searchMgtv(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get("https://so.mgtv.com/so?k=$keyword");
      final document = parser.parse(response.data);
      final items = document.querySelectorAll('.search-result-item');

      for (final item in items.take(6)) {
        final title = item.querySelector('.title')?.text.trim() ?? '';
        final cover = item.querySelector('img')?.attributes['src'] ?? '';
        final link = item.querySelector('a')?.attributes['href'] ?? '';

        if (title.isNotEmpty && link.contains('mgtv.com')) {
          results.add(SearchResult(
            title: title,
            cover: cover.startsWith('//') ? 'https:$cover' : cover,
            url: link.startsWith('http') ? link : 'https:$link',
            platform: '芒果TV',
          ));
        }
      }
    } catch (e) {
      print('芒果TV搜索失败: $e');
    }
  }

  Future<void> _parseMgtvEpisodes(String html, SearchResult result) async {
    final document = parser.parse(html);
    final episodeItems = document.querySelectorAll('.episode-list-item a');

    for (int i = 0; i < episodeItems.length; i++) {
      final item = episodeItems[i];
      final title = item.text.trim();
      final url = item.attributes['href'] ?? '';

      if (url.isNotEmpty) {
        result.episodes.add(Episode(
          title: title.isEmpty ? '第${i+1}集' : title,
          url: url.startsWith('http') ? url : 'https:$url',
          number: i+1,
        ));
      }
    }
  }
}