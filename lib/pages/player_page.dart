import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/constants.dart';

class PlayerPage extends StatefulWidget {
  final String keyword;
  const PlayerPage({super.key, required this.keyword});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  InAppWebViewController? _webViewController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  String? _capturedVideoUrl;
  bool _isLoading = true;
  bool _captureFinished = false;
  int _currentParserIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String get _currentParserUrl {
    return '${AppConstants.parseInterfaces[_currentParserIndex]}${Uri.encodeComponent(widget.keyword)}';
  }

  void _switchParser(int index) {
    if (_captureFinished) return;
    setState(() {
      _currentParserIndex = index;
      _isLoading = true;
      _errorMessage = null;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_currentParserUrl)),
    );
  }

  Future<void> _initializeVideoPlayer(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '播放失败: $e';
        _isLoading = false;
      });
    }
  }

  void _onVideoUrlCaptured(String url) {
    if (_captureFinished) return;
    _captureFinished = true;
    _capturedVideoUrl = url;
    _webViewController?.stopLoading();
    _initializeVideoPlayer(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.keyword),
        backgroundColor: Colors.black,
        actions: _captureFinished
            ? null
            : [
                PopupMenuButton<int>(
                  icon: const Icon(Icons.swap_horiz),
                  itemBuilder: (context) => List.generate(
                    AppConstants.interfaceNames.length,
                    (index) => PopupMenuItem(
                      value: index,
                      child: Text(
                        AppConstants.interfaceNames[index],
                        style: TextStyle(
                          color: index == _currentParserIndex ? Colors.blue : null,
                        ),
                      ),
                    ),
                  ),
                  onSelected: _switchParser,
                ),
              ],
      ),
      body: _capturedVideoUrl != null
          ? (_chewieController != null)
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_currentParserUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldInterceptRequest: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  shouldInterceptRequest: (controller, request) async {
                    final url = request.url.toString();
                    if (url.contains('.m3u8') || url.contains('.mp4')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onVideoUrlCaptured(url);
                      });
                    }
                    return null;
                  },
                  onLoadStop: (controller, url) {
                    if (!_captureFinished) {
                      setState(() => _isLoading = false);
                    }
                  },
                  onLoadError: (controller, url, code, message) {
                    if (!_captureFinished) {
                      setState(() {
                        _errorMessage = '加载失败: $message';
                        _isLoading = false;
                      });
                    }
                  },
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
