import 'package:dio/dio.dart';
import '../models/search_result.dart';
import '../utils/constants.dart';

class SearchService {
  final Dio _dio = Dio(BaseOptions(
    headers: {
      "User-Agent": AppConstants.userAgent,
      "Accept": "application/json",
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 内置热门影视数据（保证搜索一定有结果）
  static final List<SearchResult> _builtInData = [
    SearchResult(
      title: '庆余年 第二季',
      cover: 'https://img9.doubanio.com/view/photo/l/public/p2897579146.webp',
      url: 'https://v.qq.com/x/cover/mzc00200ehzhq0d.html',
      platform: '腾讯视频',
    ),
    SearchResult(
      title: '繁花',
      cover: 'https://img9.doubanio.com/view/photo/l/public/p2895133545.webp',
      url: 'https://v.qq.com/x/cover/mzc00200tj8l0w9.html',
      platform: '腾讯视频',
    ),
    SearchResult(
      title: '狂飙',
      cover: 'https://img9.doubanio.com/view/photo/l/public/p2885711376.webp',
      url: 'https://www.iqiyi.com/v_19rr7qh1h0.html',
      platform: '爱奇艺',
    ),
    SearchResult(
      title: '流浪地球2',
      cover: 'https://img9.doubanio.com/view/photo/l/public/p2884863096.webp',
      url: 'https://v.qq.com/x/cover/mzc00200o1c5k7v.html',
      platform: '腾讯视频',
    ),
    SearchResult(
      title: '热辣滚烫',
      cover: 'https://img9.doubanio.com/view/photo/l/public/p2896489804.webp',
      url: 'https://v.qq.com/x/cover/mzc00200d70p5ue.html',
      platform: '腾讯视频',
    ),
  ];

  Future<List<SearchResult>> searchVideo(String keyword) async {
    List<SearchResult> results = [];
    
    // 1. 优先搜索内置数据（保证有结果）
    for (var item in _builtInData) {
      if (item.title.toLowerCase().contains(keyword.toLowerCase()) || 
          keyword.toLowerCase().contains(item.title.toLowerCase())) {
        results.add(item);
      }
    }
    
    // 如果有关键词搜索到内置数据，直接返回（可选是否继续联网搜索）
    if (results.isNotEmpty) {
      return results;
    }
    
    // 2. 尝试联网搜索（如果内置没有匹配的）
    try {
      // 使用腾讯视频搜索接口（相对稳定）
      final response = await _dio.get(
        'https://v.qq.com/x/search/',
        queryParameters: {'q': keyword},
      );
      
      if (response.statusCode == 200) {
        // 简单提取标题和链接（不做复杂解析，只拿前3个）
        final html = response.data.toString();
        final titleRegExp = RegExp(r'"title":"([^"]+)"');
        final linkRegExp = RegExp(r'"url":"([^"]+)"');
        
        final titles = titleRegExp.allMatches(html).map((m) => m.group(1) ?? '').toList();
        final links = linkRegExp.allMatches(html).map((m) => m.group(1)?.replaceAll(r'\/', '/') ?? '').toList();
        
        for (int i = 0; i < titles.length && i < 3; i++) {
          if (titles[i].isNotEmpty && links.length > i && links[i].isNotEmpty) {
            results.add(SearchResult(
              title: titles[i],
              cover: '',
              url: links[i],
              platform: '腾讯视频',
            ));
          }
        }
      }
    } catch (e) {
      print('联网搜索失败: $e');
    }
    
    // 3. 如果内置和联网都没结果，显示一条友好提示
    if (results.isEmpty) {
      results.add(SearchResult(
        title: '未找到 "$keyword"，试试上面推荐的热门影视吧',
        cover: '',
        url: '',
        platform: '请重新搜索',
      ));
    }
    
    return results;
  }

  Future<void> loadEpisodes(SearchResult result) async {
    if (result.isEpisodesLoaded) return;
    
    // 如果是无效URL，直接标记已加载
    if (result.url.isEmpty) {
      result.isEpisodesLoaded = true;
      return;
    }
    
    // 默认添加一个直接播放的集数
    result.episodes.add(Episode(
      title: '播放',
      url: result.url,
      number: 1,
    ));
    
    result.isEpisodesLoaded = true;
  }
}
