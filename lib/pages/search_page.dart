import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/video.dart';
import '../models/source.dart';
import '../widgets/video_card.dart';
import '../widgets/loading_widget.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  final SiteRule? site;
  const SearchPage({super.key, this.site});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<VideoItem> _results = [];
  bool _isSearching = false;

  Future<void> _search() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty || widget.site == null) return;
    setState(() => _isSearching = true);
    final results = await ApiService().search(widget.site!, keyword);
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '输入关键词搜索',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: _isSearching
          ? const LoadingWidget()
          : _results.isEmpty
              ? const Center(child: Text('暂无结果', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (ctx, index) {
                    final video = _results[index];
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
