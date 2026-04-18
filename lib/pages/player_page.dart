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
  // 状态：0 = 显示WebView搜索结果，让用户点选；1 = 已捕获视频，原生播放
  int _stage = 0;
  
  InAppWebViewController? _webViewController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _capturedUrl;
  String? _errorMessage;
  int _currentParserIndex = 0;

  String get _parserUrl {
    return '${AppConstants.parseInterfaces[_currentParserIndex]}${Uri.encodeComponent(widget.keyword)}';
  }

  void _switchParser(int index) {
    if (_stage != 0) return;
    setState(() {
      _currentParserIndex = index;
      _errorMessage = null;
    });
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(_parserUrl)));
  }

  /// 初始化原生播放器
  Future<void> _initPlayer(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        allowFullScreen: true,
        showControls: true,
        fullScreenByDefault: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
      );
      setState(() {
        _stage = 1;
        _capturedUrl = url;
      });
    } catch (e) {
      setState(() => _errorMessage = '播放出错: $e');
    }
  }

  /// 嗅探到视频地址
  void _onUrlCaptured(String url) {
    if (_stage != 0) return;
    _webViewController?.stopLoading();
    _initPlayer(url);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _stage == 0
          ? AppBar(
              title: Text(widget.keyword),
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
                          color: index == _currentParserIndex ? Colors.blue : null,
                        ),
                      ),
                    ),
                  ),
                  onSelected: _switchParser,
                ),
              ],
            )
          : null,
      body: _stage == 0
          ? Stack(
              children: [
                // 可见的WebView，让用户手动点击搜索结果
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_parserUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldInterceptRequest: true,
                    supportZoom: false,
                  ),
                  onWebViewCreated: (c) => _webViewController = c,
                  shouldInterceptRequest: (controller, request) async {
                    final url = request.url.toString();
                    // 当用户点击某个结果进入播放页后，我们会在此处拦截到视频流
                    if (url.contains('.m3u8') || url.contains('.mp4')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onUrlCaptured(url);
                      });
                    }
                    return null;
                  },
                  onLoadError: (c, url, code, msg) {
                    setState(() => _errorMessage = '加载失败: $msg');
                  },
                ),
                // 顶部提示条
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '👇 请在下方网页中点选你想看的剧集',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(16),
                      color: Colors.red[900],
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            )
          : _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
