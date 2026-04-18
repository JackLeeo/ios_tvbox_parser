import 'package:flutter/material.dart';
import '../services/video_api_service.dart';
import '../models/video_model.dart';
import 'video_detail_page.dart';
import 'search_page.dart';
import 'history_page.dart';
import 'favorite_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VideoApiService _apiService = VideoApiService();
  final PageController _pageController = PageController();
  int _currentCategory = 1; // 1:电影 2:电视剧 3:综艺 4:动漫
  String _currentRank = 'hot'; // hot / new / rank
  List<VideoItem> _videos = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final videos = await _apiService.getVideoList(
      cat: _currentCategory,
      type: _currentRank,
      page: 1,
    );
    setState(() {
      _videos = videos;
      _isLoading = false;
      _currentPage = 1;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final moreVideos = await _apiService.getVideoList(
      cat: _currentCategory,
      type: _currentRank,
      page: _currentPage + 1,
    );
    setState(() {
      _videos.addAll(moreVideos);
      _isLoading = false;
      _currentPage++;
    });
  }

  void _switchCategory(int cat) {
    setState(() => _currentCategory = cat);
    _loadVideos();
  }

  void _switchRank(String rank) {
    setState(() => _currentRank = rank);
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('视频解析', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(context, 
              MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类切换
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryChip('电影', 1),
                _buildCategoryChip('电视剧', 2),
                _buildCategoryChip('综艺', 3),
                _buildCategoryChip('动漫', 4),
              ],
            ),
          ),
          // 排序切换
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRankChip('热播', 'hot'),
                const SizedBox(width: 16),
                _buildRankChip('最新', 'new'),
                const SizedBox(width: 16),
                _buildRankChip('好评', 'rank'),
              ],
            ),
          ),
          // 视频网格
          Expanded(
            child: _isLoading && _videos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _videos.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _videos.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final video = _videos[index];
                      return _buildVideoCard(video);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, 
              MaterialPageRoute(builder: (_) => const HistoryPage()));
          } else if (index == 2) {
            Navigator.push(context, 
              MaterialPageRoute(builder: (_) => const FavoritePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '历史'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '收藏'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int cat) {
    final isSelected = _currentCategory == cat;
    return GestureDetector(
      onTap: () => _switchCategory(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRankChip(String label, String rank) {
    final isSelected = _currentRank == rank;
    return GestureDetector(
      onTap: () => _switchRank(rank),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoItem video) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoDetailPage(video: video),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                video.cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (video.score != null)
            Text(
              '⭐ ${video.score}',
              style: const TextStyle(color: Colors.orange, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
