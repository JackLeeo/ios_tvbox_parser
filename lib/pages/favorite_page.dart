import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/video_model.dart';
import 'video_detail_page.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final StorageService _storageService = StorageService();
  List<VideoItem> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _favorites = _storageService.getFavorites();
    });
  }

  Future<void> _removeFavorite(String videoId) async {
    await _storageService.removeFavorite(videoId);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        centerTitle: true,
      ),
      body: _favorites.isEmpty
          ? const Center(
              child: Text(
                '暂无收藏',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                return Dismissible(
                  key: Key(favorite.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _removeFavorite(favorite.id);
                  },
                  child: ListTile(
                    leading: Image.network(
                      favorite.cover,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 70,
                          color: Colors.grey[800],
                          child: const Icon(Icons.video_library, color: Colors.grey),
                        );
                      },
                    ),
                    title: Text(favorite.title),
                    subtitle: Text(
                      favorite.year ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoDetailPage(video: favorite),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
