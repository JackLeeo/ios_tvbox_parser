import 'package:flutter/material.dart';
import '../models/video.dart';
import '../models/source.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/video_card.dart';
import '../widgets/loading_widget.dart';
import 'category_page.dart';
import 'search_page.dart';
import 'detail_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final SourceConfig config;
  final String sourceInput;

  const HomePage({super.key, required this.config, required this.sourceInput});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SiteRule? _currentSite;
  List<VideoItem> _videos = [];
  bool _isLoading = true;
  int _currentCat = 1;

  @override
  void initState() {
    super.initState();
    _currentSite = widget.config.sites.isNotEmpty ? widget.config.sites[0] : null;
    if (_currentSite != null) {
      _loadVideos();
    } else {
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
    _loadVideos();
  }

  void _changeSite(SiteRule site) {
    setState(() {
      _currentSite = site;
    });
    _loadVideos();
  }

  void _openSettings() async {
    await StorageService().clearSource();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SearchPage(site: _currentSite)),
            ),
          ),
          PopupMenuButton<SiteRule>(
            icon: const Icon(Icons.swap_vert),
            onSelected: _changeSite,
            itemBuilder: (context) => widget.config.sites.map((site) {
              return PopupMenuItem(
                value: site,
                child: Text(site.name),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _videos.isEmpty
              ? const Center(
                  child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
                )
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
                        MaterialPageRoute(
                          builder: (_) => DetailPage(
                            site: _currentSite!,
                            video: video,
                          ),
                        ),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CategoryPage(site: _currentSite)),
            );
          }
        },
      ),
    );
  }
}
