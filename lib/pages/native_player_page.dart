import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/constants.dart';

class NativePlayerPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String episodeTitle;

  const NativePlayerPage({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.episodeTitle,
  });

  @override
  State<NativePlayerPage> createState() => _NativePlayerPageState();
}

class _NativePlayerPageState extends State<NativePlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  int _currentInterfaceIndex = 0;
  bool _isLoading = true;
  String _currentParseUrl = '';

  @override
  void initState() {
    super.initState();
    _buildParseUrl();
  }

  void _buildParseUrl() {
    final parseBase = AppConstants.parseInterfaces[_currentInterfaceIndex];
    setState(() {
      _currentParseUrl = '$parseBase${widget.videoUrl}';
    });
    _initializePlayer(_currentParseUrl);
  }

  Future<void> _initializePlayer(String url) async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.shade700,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),
      autoInitialize: true,
    );
    
    setState(() => _isLoading = false);
  }

  void _switchInterface(int index) {
    setState(() {
      _currentInterfaceIndex = index;
      _isLoading = true;
    });
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    _buildParseUrl();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.episodeTitle),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.swap_horiz),
            itemBuilder: (context) => List.generate(
              AppConstants.interfaceNames.length,
              (index) => PopupMenuItem(
                value: index,
                child: Text(
                  AppConstants.interfaceNames[index],
                  style: TextStyle(
                    color: index == _currentInterfaceIndex ? Colors.blue : Colors.white,
                  ),
                ),
              ),
            ),
            onSelected: _switchInterface,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
      ),
    );
  }
}
