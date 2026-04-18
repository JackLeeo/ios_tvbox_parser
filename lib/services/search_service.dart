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
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  /// 搜索影视：优先使用解析接口直接搜索关键词，失败后降级为多平台 HTML 解析
  Future<List<SearchResult>> searchVideo(String keyword) async {
    List<SearchResult> results = [];

    // 1. 尝试使用解析接口直接搜索（把关键词传给解析接口）
    for (int i = 0; i < 3 && i < AppConstants.parseInterfaces.length; i++) {
      final interface = AppConstants.parseInterfaces[i];
      try {
        final searchUrl = '$interface$keyword';
        final response = await _dio.get(searchUrl);
        final html = response.data.toString();
        final extracted = _extractFromHtml(html, interface);
        if (extracted.isNotEmpty) {
          results.addAll(extracted);
          break; // 只要有一个接口返回了结果就停止
        }
      } catch (e) {
        print('接口 ${AppConstants.interfaceNames[i]} 搜索失败: $e');
        continue;
      }
    }

    // 2. 如果解析接口都失败，降级为原有的多平台 HTML 解析
    if (results.isEmpty) {
      await Future.wait([
        _searchTencent(keyword, results),
        _searchIqiyi(keyword, results),
        _searchYouku(keyword, results),
        _searchMgtv(keyword, results),
      ]);
    }

    // 3. 如果依然没有结果，返回一个提示
    if (results.isEmpty) {
      results.add(SearchResult(
        title: '未找到 "$keyword" 的相关视频',
        cover: '',
        url: '',
        platform: '请尝试其他关键词',
      ));
    }

    return results;
  }

  /// 从解析接口返回的 HTML 中提取影视信息
  List<SearchResult> _extractFromHtml(String html, String interface) {
    final document = parser.parse(html);
    final results = <SearchResult>[];

    // 通用选择器：查找视频列表项
    final selectors = [
      '.video-item', '.search-item', '.result-item', '.list-item',
      '[class*="video"]', '[class*="result"]', '[class*="item"]',
    ];

    List<dynamic>? items;
    for (final sel in selectors) {
      items = document.querySelectorAll(sel);
      if (items.isNotEmpty) break;
    }

    if (items != null && items.isNotEmpty) {
      for (final item in items.take(6)) {
        final titleElem = item.querySelector('a') ??
                         item.querySelector('.title') ??
                         item.querySelector('[class*="title"]');
        final title = titleElem?.text.trim() ?? '';

        final img = item.querySelector('img');
        final cover = img?.attributes['src'] ?? img?.attributes['data-src'] ?? '';

        final link = item.querySelector('a')?.attributes['href'] ?? '';

        if (title.isNotEmpty) {
          results.add(SearchResult(
            title: title,
            cover: _fixUrl(cover),
            url: _fixUrl(link),
            platform: _guessPlatform(interface),
          ));
        }
      }
    }

    // 如果没提取到列表，可能是直接进入了播放页（只有一部剧）
    if (results.isEmpty) {
      final titleTag = document.querySelector('title');
      final title = titleTag?.text.replaceAll(RegExp(r'[-–|].*'), '').trim() ?? '';
      final cover = document.querySelector('img')?.attributes['src'] ?? '';
      final iframe = document.querySelector('iframe');
      final videoSrc = iframe?.attributes['src'] ?? '';

      if (title.isNotEmpty) {
        results.add(SearchResult(
          title: title,
          cover: _fixUrl(cover),
          url: videoSrc.isNotEmpty ? videoSrc : interface,
          platform: _guessPlatform(interface),
        ));
      }
    }

    return results;
  }

  /// 补全 URL 协议
  String _fixUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('//')) return 'https:$url';
    if (!url.startsWith('http')) return 'https://$url';
    return url;
  }

  /// 根据接口名称猜测平台名
  String _guessPlatform(String interface) {
    for (int i = 0; i < AppConstants.parseInterfaces.length; i++) {
      if (interface.contains(AppConstants.parseInterfaces[i].split('/')[2])) {
        return AppConstants.interfaceNames[i];
      }
    }
    return '解析资源';
  }

  /// 加载剧集列表
  Future<void> loadEpisodes(SearchResult result) async {
    if (result.isEpisodesLoaded) return;

    try {
      final response = await _dio.get(result.url);
      final html = response.data.toString();
      final document = parser.parse(html);

      var episodeItems = document.querySelectorAll('.episode a, .play-list a, [class*="episode"] a');
      if (episodeItems.isEmpty) {
        episodeItems = document.querySelectorAll('a[href*="episode"], a[href*="play"]');
      }

      for (int i = 0; i < episodeItems.length; i++) {
        final item = episodeItems[i];
        final title = item.text.trim();
        final url = item.attributes['href'] ?? '';
        if (url.isNotEmpty) {
          result.episodes.add(Episode(
            title: title.isEmpty ? '第${i+1}集' : title,
            url: _fixUrl(url),
            number: i+1,
          ));
        }
      }

      if (result.episodes.isEmpty) {
        result.episodes.add(Episode(
          title: '播放',
          url: result.url,
          number: 1,
        ));
      }
    } catch (e) {
      print('解析剧集失败: $e');
      result.episodes.add(Episode(
        title: '直接播放',
        url: result.url,
        number: 1,
      ));
    }

    result.isEpisodesLoaded = true;
  }

  // ==================== 以下是原有的多平台 HTML 解析备份逻辑 ====================

  Future<void> _searchTencent(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get(
        'https://v.qq.com/x/search/',
        queryParameters: {'q': keyword},
      );
      final document = parser.parse(response.data);
      var items = document.querySelectorAll('.result_item_v');
      if (items.isEmpty) items = document.querySelectorAll('.result_item');
      if (items.isEmpty) items = document.querySelectorAll('[class*="result_item"]');

      for (final item in items.take(6)) {
        final titleElem = item.querySelector('.result_title') ?? 
                         item.querySelector('.title') ??
                         item.querySelector('[class*="title"]');
        final title = titleElem?.text.trim() ?? '';
        final imgElem = item.querySelector('img');
        final cover = imgElem?.attributes['src'] ?? '';
        final linkElem = item.querySelector('a');
        final link = linkElem?.attributes['href'] ?? '';
        
        if (title.isNotEmpty && link.contains('v.qq.com')) {
          results.add(SearchResult(
            title: title,
            cover: _fixUrl(cover),
            url: _fixUrl(link),
            platform: '腾讯视频',
          ));
        }
      }
    } catch (e) {
      print('腾讯搜索失败: $e');
    }
  }

  Future<void> _searchIqiyi(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get('https://so.iqiyi.com/so/q_$keyword');
      final document = parser.parse(response.data);
      var items = document.querySelectorAll('.qy-search-result-item');
      if (items.isEmpty) items = document.querySelectorAll('.search-item');
      if (items.isEmpty) items = document.querySelectorAll('[class*="search-result"]');

      for (final item in items.take(6)) {
        final titleElem = item.querySelector('.qy-search-result-title') ?? 
                         item.querySelector('.title') ??
                         item.querySelector('a');
        final title = titleElem?.text.trim() ?? '';
        final imgElem = item.querySelector('img');
        final cover = imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'] ?? '';
        final linkElem = item.querySelector('a');
        final link = linkElem?.attributes['href'] ?? '';
        
        if (title.isNotEmpty && link.contains('iqiyi.com')) {
          results.add(SearchResult(
            title: title,
            cover: _fixUrl(cover),
            url: _fixUrl(link),
            platform: '爱奇艺',
          ));
        }
      }
    } catch (e) {
      print('爱奇艺搜索失败: $e');
    }
  }

  Future<void> _searchYouku(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get('https://so.youku.com/search_video/q_$keyword');
      final document = parser.parse(response.data);
      var items = document.querySelectorAll('.so-result-item');
      if (items.isEmpty) items = document.querySelectorAll('[class*="result"]');

      for (final item in items.take(6)) {
        final titleElem = item.querySelector('.so-title') ?? 
                         item.querySelector('.title') ??
                         item.querySelector('a');
        final title = titleElem?.text.trim() ?? '';
        final imgElem = item.querySelector('img');
        final cover = imgElem?.attributes['src'] ?? '';
        final linkElem = item.querySelector('a');
        final link = linkElem?.attributes['href'] ?? '';
        
        if (title.isNotEmpty && link.contains('youku.com')) {
          results.add(SearchResult(
            title: title,
            cover: _fixUrl(cover),
            url: _fixUrl(link),
            platform: '优酷',
          ));
        }
      }
    } catch (e) {
      print('优酷搜索失败: $e');
    }
  }

  Future<void> _searchMgtv(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get(
        'https://so.mgtv.com/so',
        queryParameters: {'k': keyword},
      );
      final document = parser.parse(response.data);
      var items = document.querySelectorAll('.search-result-item');
      if (items.isEmpty) items = document.querySelectorAll('[class*="result"]');

      for (final item in items.take(6)) {
        final titleElem = item.querySelector('.title') ?? item.querySelector('a');
        final title = titleElem?.text.trim() ?? '';
        final imgElem = item.querySelector('img');
        final cover = imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'] ?? '';
        final linkElem = item.querySelector('a');
        final link = linkElem?.attributes['href'] ?? '';
        
        if (title.isNotEmpty && link.contains('mgtv.com')) {
          results.add(SearchResult(
            title: title,
            cover: _fixUrl(cover),
            url: _fixUrl(link),
            platform: '芒果TV',
          ));
        }
      }
    } catch (e) {
      print('芒果TV搜索失败: $e');
    }
  }
}
