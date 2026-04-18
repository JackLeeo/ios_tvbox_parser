import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/api_service.dart';
import '../models/source.dart';
import '../utils/constants.dart';

class PlayerPage extends StatefulWidget {
  final SiteRule site;
  final String videoUrl;
  final String videoTitle;
  final String flag;

  const PlayerPage({
    super.key,
    required this.site,
    required this.videoUrl,
    required this.videoTitle,
    required this.flag,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  int _parserIndex = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // 优先通过 Node.js 解析真实播放地址
    String realUrl = await ApiService().getPlayUrl(widget.site, widget.flag, widget.videoUrl);

    // 如果解析失败，回退到公共解析接口
    if (realUrl.isEmpty) {
      final base = AppConstants.parseInterfaces[_parserIndex];
      realUrl = '$base${Uri.encodeComponent(widget.videoUrl)}';
    }

    _videoController = VideoPlayerController.networkUrl(Uri.parse(realUrl));
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey.shade800,
        bufferedColor: Colors.grey.shade600,
      ),
    );

    setState(() => _isLoading = false);
  }

  void _switchParser(int index) async {
    setState(() {
      _parserIndex = index;
      _isLoading = true;
    });
    _chewieController?.dispose();
    await _videoController.dispose();
    await _initPlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.videoTitle),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.swap_horiz),
            itemBuilder: (context) => List.generate(
              AppConstants.interfaceNames.length,
              (index) => PopupMenuItem(
                value: index,
                child: Text(AppConstants.interfaceNames[index]),
              ),
            ),
            onSelected: _switchParser,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Chewie(controller: _chewieController!),
    );
  }
}
