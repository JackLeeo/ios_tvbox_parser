import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';
import '../models/search_result.dart';
import 'player_page.dart';

class EpisodePage extends StatefulWidget {
  final SearchResult searchResult;
  final int initialEpisodeIndex;

  const EpisodePage({
    super.key,
    required this.searchResult,
    this.initialEpisodeIndex = -1,
  });

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage> {
  final SearchService _searchService = SearchService();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _checkFavorite();
  }

  Future<void> _loadEpisodes() async {
    await _searchService.loadEpisodes(widget.searchResult);
    setState(() => _isLoading = false);

    if (widget.initialEpisodeIndex >= 0 && widget.searchResult.episodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerPage(
                videoUrl: widget.searchResult.episodes[widget.initialEpisodeIndex].url,
                videoTitle: '${widget.searchResult.title} ${widget.searchResult.episodes[widget.initialEpisodeIndex].title}',
                episodes: widget.searchResult.episodes,
                currentEpisodeIndex: widget.initialEpisodeIndex,
                searchResult: widget.searchResult,
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _checkFavorite() async {
    setState(() {
      _isFavorite = _storageService.isFavorite(widget.searchResult.url);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storageService.removeFavorite(widget.searchResult.url);
    } else {
      await _storageService.addFavorite(widget.searchResult);
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.searchResult.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? '取消收藏' : '添加收藏',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitFadingCircle(color: Colors.blue, size: 50),
            )
          : widget.searchResult.episodes.isEmpty
              ? Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerPage(
                            videoUrl: widget.searchResult.url,
                            videoTitle: widget.searchResult.title,
                            episodes: const [],
                            currentEpisodeIndex: 0,
                            searchResult: widget.searchResult,
                          ),
                        ),
                      );
                    },
                    child: const Text('直接播放'),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: widget.searchResult.episodes.length,
                  itemBuilder: (context, index) {
                    final episode = widget.searchResult.episodes[index];

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerPage(
                              videoUrl: episode.url,
                              videoTitle: '${widget.searchResult.title} ${episode.title}',
                              episodes: widget.searchResult.episodes,
                              currentEpisodeIndex: index,
                              searchResult: widget.searchResult,
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
    );
  }
}