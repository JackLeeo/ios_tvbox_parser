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
  // WebView 相关
  InAppWebViewController? _webViewController;
  bool _showWebView = true;          // 当前是否显示 WebView
  bool _isLoading = true;
  String? _errorMessage;

  // 原生播放器相关
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _videoUrl;

  // 当前解析线路
  int _currentParserIndex = 0;

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

  String get _parserUrl {
    return '${AppConstants.parseInterfaces[_currentParserIndex]}${Uri.encodeComponent(widget.keyword)}';
  }

  void _switchParser(int index) {
    if (!_showWebView) return;
    setState(() {
      _currentParserIndex = index;
      _isLoading = true;
      _errorMessage = null;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_parserUrl)),
    );
  }

  /// 当嗅探到真实视频流地址时调用
  Future<void> _onVideoUrlCaptured(String url) async {
    if (!_showWebView) return;
    
    // 停止 WebView 加载，隐藏 WebView
    _webViewController?.stopLoading();
    
    setState(() {
      _showWebView = false;
      _isLoading = true;
    });
    
    // 初始化原生播放器
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
        fullScreenByDefault: false,
        autoInitialize: true,
        showOptions: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
      );

      setState(() {
        _videoUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '原生播放器初始化失败: $e';
        _isLoading = false;
        _showWebView = true;  // 失败则退回 WebView
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showWebView
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
          : null, // 原生播放时隐藏 AppBar（全屏时自动隐藏）
      body: _showWebView
          ? Stack(
              children: [
                // 可见的 WebView，让用户手动选择剧集
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_parserUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldInterceptRequest: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  // 核心：拦截所有网络请求，嗅探视频流
                  shouldInterceptRequest: (controller, request) async {
                    final url = request.url.toString();
                    // 一旦出现 .m3u8 或 .mp4，立即拦截并切换
                    if (url.contains('.m3u8') || url.contains('.mp4')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onVideoUrlCaptured(url);
                      });
                    }
                    return null;
                  },
                  onLoadStop: (controller, url) {
                    setState(() => _isLoading = false);
                  },
                  onLoadError: (controller, url, code, message) {
                    setState(() {
                      _errorMessage = '加载失败: $message';
                      _isLoading = false;
                    });
                  },
                ),
                // 加载指示器
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                // 错误提示
                if (_errorMessage != null && !_isLoading)
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
            )
          : _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
