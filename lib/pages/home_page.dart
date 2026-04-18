import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/source_parser.dart';
import '../services/api_service.dart';
import '../models/video.dart';
import '../models/source.dart';
import '../widgets/video_card.dart';
import '../utils/constants.dart';
import 'category_page.dart';
import 'search_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SourceConfig? _config;
  SiteRule? _currentSite;
  List<VideoItem> _videos = [];
  bool _isLoading = true;
  int _currentCat = 1; // 1:电影 2:电视剧 3:综艺 4:动漫

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  Future<void> _loadSource() async {
    try {
      final config = await SourceParser().loadSource(AppConstants.defaultSourceUrl);
      setState(() {
        _config = config;
        _currentSite = config.sites.isNotEmpty ? config.sites[0] : null;
      });
      if (_currentSite != null) {
        _loadVideos();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    if (_currentSite == null) return;
    setState(() => _isLoading = true);
    final videos = await ApiService().getHomeList(_currentSite!, page: 1);
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  void _switchCategory(int cat) {
    setState(() => _currentCat = cat);
    // 实际可按分类加载，这里简化
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_config?.name ?? 'TVBox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(site: _currentSite))),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitFadingCircle(color: Colors.blue))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _videos.length,
              itemBuilder: (ctx, index) {
                final video = _videos[index];
                return VideoCard(
                  video: video,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailPage(site: _currentSite!, video: video)),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: '分类'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(site: _currentSite)));
          }
        },
      ),
    );
  }
}
