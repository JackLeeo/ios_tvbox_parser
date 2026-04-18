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
      // 注意：需要调整存储模型以适配新结构
      // 这里先简化处理
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
                          '${widget.video.year ?? ""} · ${widget.video.area ?? ""}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // 播放源选择
                        if (_sources.isNotEmpty) ...[
                          const Text(
                            '播放源',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _sources.map((source) {
                              final isSelected = _selectedSource == source;
                              return ChoiceChip(
                                label: Text(source.name),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedSource = source);
                                },
                                backgroundColor: Colors.grey[800],
                                selectedColor: Colors.blue,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // 剧集列表
                        if (_selectedSource != null) ...[
                          const Text(
                            '剧集列表',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _selectedSource!.episodes.length,
                            itemBuilder: (context, index) {
                              final episode = _selectedSource!.episodes[index];
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  padding: const EdgeInsets.all(4),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NativePlayerPage(
                                        videoUrl: episode.url,
                                        videoTitle: '${widget.video.title} ${episode.title}',
                                        episodeTitle: episode.title,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  episode.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
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
