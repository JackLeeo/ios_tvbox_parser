import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/video.dart';
import '../models/source.dart';
import 'player_page.dart';

class DetailPage extends StatefulWidget {
  final SiteRule site;
  final VideoItem video;
  const DetailPage({super.key, required this.site, required this.video});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<Episode> _episodes = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _checkFavorite();
  }

  Future<void> _loadEpisodes() async {
    final episodes = await ApiService().getEpisodes(widget.site, widget.video.id);
    setState(() {
      _episodes = episodes;
      _isLoading = false;
    });
  }

  Future<void> _checkFavorite() async {
    await _storage.init();
    setState(() => _isFavorite = _storage.isFavorite(widget.video.id));
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storage.removeFavorite(widget.video.id);
    } else {
      await _storage.addFavorite(widget.video);
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
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
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
                        Text(widget.video.title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (widget.video.year != null || widget.video.area != null)
                          Text('${widget.video.year ?? ''} · ${widget.video.area ?? ''}',
                              style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        if (_episodes.isNotEmpty) ...[
                          const Text('剧集列表', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                            itemCount: _episodes.length,
                            itemBuilder: (ctx, index) {
                              final ep = _episodes[index];
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  padding: const EdgeInsets.all(4),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlayerPage(
                                        site: widget.site,
                                        videoUrl: ep.url,
                                        videoTitle: '${widget.video.title} ${ep.name}',
                                        flag: '',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(ep.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.center),
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
