import 'package:flutter/material.dart';
import 'package:hls_proplayer/hls_proplayer.dart';
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
  String _currentParseUrl = '';
  int _currentInterfaceIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildParseUrl();
  }

  void _buildParseUrl() {
    // 使用解析接口将视频页面 URL 转换为可播放的流地址
    final parseBase = AppConstants.parseInterfaces[_currentInterfaceIndex];
    setState(() {
      _currentParseUrl = '$parseBase${widget.videoUrl}';
    });
  }

  void _switchInterface(int index) {
    setState(() {
      _currentInterfaceIndex = index;
      _isLoading = true;
    });
    _buildParseUrl();
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
        child: _currentParseUrl.isEmpty
            ? const CircularProgressIndicator()
            : HlsPlayer(
                url: _currentParseUrl,
                mode: Mode.recorded,
                autoplay: true,
                looping: false,
                controlsTheme: const HlsControlsTheme(
                  progressActiveColor: Colors.blue,
                  progressInactiveColor: Colors.grey,
                  liveIndicatorColor: Colors.red,
                  iconColor: Colors.white,
                  iconSize: 24.0,
                ),
                placeholderBuilder: (ctx) => const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
                bufferingIndicatorBuilder: (ctx) => const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              ),
      ),
    );
  }
}
