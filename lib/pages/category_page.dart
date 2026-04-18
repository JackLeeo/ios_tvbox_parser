import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import '../models/video.dart';
import '../models/source.dart';
import '../widgets/video_card.dart';
import 'detail_page.dart';

class CategoryPage extends StatefulWidget {
  final SiteRule? site;
  const CategoryPage({super.key, this.site});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late List<VideoItem> _videos = [];
  bool _isLoading = true;
  int _currentCat = 1;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (widget.site == null) return;
    setState(() => _isLoading = true);
    final videos = await ApiService().getHomeList(widget.site!, page: 1);
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分类')),
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
                    MaterialPageRoute(
                      builder: (_) => DetailPage(site: widget.site!, video: video),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
