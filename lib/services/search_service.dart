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
    connectTimeout: const Duration(seconds: 15),
  ));

  // 聚合搜索多个平台
  Future<List<SearchResult>> searchVideo(String keyword) async {
    final List<SearchResult> results = [];
    
    // 并发请求所有平台，哪个成功就加哪个
    await Future.wait([
      _searchTencent(keyword, results),
      _searchIqiyi(keyword, results),
      _searchYouku(keyword, results),
      _searchMgtv(keyword, results),
    ]);
    
    // 如果所有平台都失败了，给用户一个明确提示
    if (results.isEmpty) {
      results.add(SearchResult(
        title: '未找到 "$keyword" 的相关视频',
        cover: '',
        url: '',
        platform: '请检查网络或更换关键词',
      ));
    }
    
    return results;
  }

  // 解析剧集列表（保留原有的多平台解析能力）
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
        default:
          // 如果是其他平台，直接添加一个播放链接
          result.episodes.add(Episode(
            title: '播放',
            url: result.url,
            number: 1,
          ));
      }
      result.isEpisodesLoaded = true;
    } catch (e) {
      print('解析剧集失败: $e');
      // 即使解析失败，也提供一个直接播放的选项
      result.episodes.add(Episode(
        title: '直接播放',
        url: result.url,
        number: 1,
      ));
      result.isEpisodesLoaded = true;
    }
  }

  // ==================== 腾讯视频 ====================
  Future<void> _searchTencent(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get(
        'https://v.qq.com/x/search/',
        queryParameters: {'q': keyword},
      );
      final document = parser.parse(response.data);
      
      // 更健壮的选择器：同时尝试新旧两种结构
      var items = document.querySelectorAll('.result_item_v');
      if (items.isEmpty) {
        items = document.querySelectorAll('.result_item');
      }
      if (items.isEmpty) {
        items = document.querySelectorAll('[class*="result_item"]');
      }

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
    var episodeItems = document.querySelectorAll('.episode-item a');
    if (episodeItems.isEmpty) {
      episodeItems = document.querySelectorAll('[class*="episode"] a');
    }

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
    
    // 如果没解析到任何剧集，添加一个直接播放
    if (result.episodes.isEmpty) {
      result.episodes.add(Episode(
        title: '播放',
        url: result.url,
        number: 1,
      ));
    }
  }

  // ==================== 爱奇艺 ====================
  Future<void> _searchIqiyi(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get(
        'https://so.iqiyi.com/so/q_$keyword',
      );
      final document = parser.parse(response.data);
      
      var items = document.querySelectorAll('.qy-search-result-item');
      if (items.isEmpty) {
        items = document.querySelectorAll('.search-item');
      }
      if (items.isEmpty) {
        items = document.querySelectorAll('[class*="search-result"]');
      }

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
    var episodeItems = document.querySelectorAll('.album-play-item a');
    if (episodeItems.isEmpty) {
      episodeItems = document.querySelectorAll('[class*="play"] a');
    }

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
    
    if (result.episodes.isEmpty) {
      result.episodes.add(Episode(
        title: '播放',
        url: result.url,
        number: 1,
      ));
    }
  }

  // ==================== 优酷 ====================
  Future<void> _searchYouku(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get(
        'https://so.youku.com/search_video/q_$keyword',
      );
      final document = parser.parse(response.data);
      
      var items = document.querySelectorAll('.so-result-item');
      if (items.isEmpty) {
        items = document.querySelectorAll('[class*="result"]');
      }

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
    var episodeItems = document.querySelectorAll('.anthology-list-item a');
    if (episodeItems.isEmpty) {
      episodeItems = document.querySelectorAll('[class*="episode"] a');
    }

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
    
    if (result.episodes.isEmpty) {
      result.episodes.add(Episode(
        title: '播放',
        url: result.url,
        number: 1,
      ));
    }
  }

  // ==================== 芒果TV ====================
  Future<void> _searchMgtv(String keyword, List<SearchResult> results) async {
    try {
      final response = await _dio.get(
        'https://so.mgtv.com/so',
        queryParameters: {'k': keyword},
      );
      final document = parser.parse(response.data);
      
      var items = document.querySelectorAll('.search-result-item');
      if (items.isEmpty) {
        items = document.querySelectorAll('[class*="result"]');
      }

      for (final item in items.take(6)) {
        final titleElem = item.querySelector('.title') ?? 
                         item.querySelector('a');
        final title = titleElem?.text.trim() ?? '';
        
        final imgElem = item.querySelector('img');
        final cover = imgElem?.attributes['src'] ?? imgElem?.attributes['data-src'] ?? '';
        
        final linkElem = item.querySelector('a');
        final link = linkElem?.attributes['href'] ?? '';
        
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
    var episodeItems = document.querySelectorAll('.episode-list-item a');
    if (episodeItems.isEmpty) {
      episodeItems = document.querySelectorAll('[class*="episode"] a');
    }

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
    
    if (result.episodes.isEmpty) {
      result.episodes.add(Episode(
        title: '播放',
        url: result.url,
        number: 1,
      ));
    }
  }
}
