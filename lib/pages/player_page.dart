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
  // WebView 相关（仅用于嗅探）
  InAppWebViewController? _webViewController;
  bool _isSniffing = true;
  String? _errorMessage;

  // 播放器相关
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
    if (!_isSniffing) return;
    setState(() {
      _currentParserIndex = index;
      _errorMessage = null;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_parserUrl)),
    );
  }

  /// 初始化原生播放器
  Future<void> _initNativePlayer(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,          // 启用全屏
        allowMuting: true,
        showControls: true,
        fullScreenByDefault: false,      // 不默认全屏
        autoInitialize: true,
        showOptions: true,               // 显示更多选项（倍速等）
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade600,
        ),
      );

      setState(() {
        _videoUrl = url;
        _isSniffing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '播放失败: $e';
      });
    }
  }

  /// 嗅探到视频地址的回调
  void _onUrlCaptured(String url) {
    if (!_isSniffing) return;
    // 停止 WebView 加载，节省资源
    _webViewController?.stopLoading();
    _initNativePlayer(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isSniffing
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
          : null, // 全屏播放时隐藏 AppBar
      body: _isSniffing
          ? Stack(
              children: [
                // 隐藏的 WebView，仅用于嗅探
                Offstage(
                  offstage: false,
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_parserUrl)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useShouldInterceptRequest: true,
                    ),
                    onWebViewCreated: (c) => _webViewController = c,
                    shouldInterceptRequest: (controller, request) async {
                      final url = request.url.toString();
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
                ),
                // 嗅探中遮罩
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          '正在嗅探视频流...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
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
