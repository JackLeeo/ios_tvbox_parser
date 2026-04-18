import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/video_api_service.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import 'native_player_page.dart';

class VideoDetailPage extends StatefulWidget {
  final VideoItem video;

  const VideoDetailPage({super.key, required this.video});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  final VideoApiService _apiService = VideoApiService();
  final StorageService _storageService = StorageService();
  Map<String, dynamic>? _detailData;
  List<VideoSource> _sources = [];
  VideoSource? _selectedSource;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkFavorite();
  }

  Future<void> _loadDetail() async {
    final data = await _apiService.getVideoDetail(
      widget.video.id,
      cat: widget.video.cat,
    );
    if (data != null) {
      final sources = _apiService.parseVideoSources(data);
      setState(() {
        _detailData = data;
        _sources = sources;
        _selectedSource = sources.isNotEmpty ? sources.first : null;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFavorite() async {
    setState(() {
      _isFavorite = _storageService.isFavorite(widget.video.id);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storageService.removeFavorite(widget.video.id);
    } else {
      await _storageService.addFavorite(widget.video);
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: SpinKitFadingCircle(color: Colors.blue))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: Colors.black,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Image.network(
                      widget.video.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.movie, size: 50),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.video.score != null)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                widget.video.score!,
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.video.year ?? ""}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // 播放按钮
                        if (_selectedSource != null && _selectedSource!.episodes.isNotEmpty)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final episode = _selectedSource!.episodes.first;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NativePlayerPage(
                                      videoUrl: episode.url,
                                      videoTitle: widget.video.title,
                                      episodeTitle: episode.title,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('立即播放'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // 简介
                        if (_detailData?['summary'] != null) ...[
                          const Text(
                            '简介',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _detailData!['summary'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
