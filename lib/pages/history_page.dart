import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/storage_models.dart';
import '../models/search_result.dart';
import 'episode_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final StorageService _storageService = StorageService();
  List<PlayHistory> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyList = _storageService.getPlayHistory();
    });
  }

  Future<void> _deleteHistory(String videoUrl) async {
    await _storageService.deletePlayHistory(videoUrl);
    _loadHistory();
  }

  Future<void> _clearAllHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('确认清空', style: TextStyle(color: Colors.white)),
        content: const Text('确定要清空所有播放历史吗？', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      await _storageService.clearAllHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放历史'),
        centerTitle: true,
        actions: [
          if (_historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: '清空历史',
            ),
        ],
      ),
      body: _historyList.isEmpty
          ? const Center(
              child: Text(
                '暂无播放历史',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final history = _historyList[index];
                return Dismissible(
                  key: Key(history.videoUrl),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteHistory(history.videoUrl);
                  },
                  child: ListTile(
                    leading: Image.network(
                      history.cover,
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
                    title: Text(history.title),
                    subtitle: Text(
                      '${history.platform} · 第${history.lastEpisodeIndex+1}集 · ${_formatDateTime(history.watchTime)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EpisodePage(
                            searchResult: SearchResult(
                              title: history.title,
                              cover: history.cover,
                              url: history.videoUrl,
                              platform: history.platform,
                            ),
                            initialEpisodeIndex: history.lastEpisodeIndex,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}-${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}