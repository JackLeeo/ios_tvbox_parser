import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';
import '../models/search_result.dart';
import '../services/storage_service.dart';
import '../models/storage_models.dart';

class PlayerPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<Episode> episodes;
  final int currentEpisodeIndex;
  final SearchResult searchResult;

  const PlayerPage({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.episodes = const [],
    this.currentEpisodeIndex = 0,
    required this.searchResult,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final WebViewController _controller;
  int _currentInterfaceIndex = 0;
  bool _isLoading = true;
  bool _isDanmakuEnabled = true;
  late int _currentEpisodeIndex;
  final StorageService _storageService = StorageService();
  DateTime _startTime = DateTime.now();
  bool _isAutoPlay = true;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.currentEpisodeIndex;
    _initWebView();
    _startProgressTimer();
  }

  @override
  void dispose() {
    _savePlayHistory();
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(AppConstants.userAgent)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            if (_isDanmakuEnabled) {
              await _enableDanmaku();
            }
            if (_isAutoPlay && widget.episodes.isNotEmpty) {
              _checkVideoEnd();
            }
          },
          onWebResourceError: (error) {
            if (_currentInterfaceIndex < AppConstants.parseInterfaces.length - 1) {
              _switchInterface();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse('${AppConstants.parseInterfaces[_currentInterfaceIndex]}${widget.episodes.isNotEmpty ? widget.episodes[_currentEpisodeIndex].url : widget.videoUrl}'),
      );
  }

  Future<void> _enableDanmaku() async {
    await _controller.runJavaScript('''
      setTimeout(() => {
        const danmakuButtons = document.querySelectorAll('[aria-label*="弹幕"], [title*="弹幕"], .danmaku-switch, .dm-switch');
        danmakuButtons.forEach(btn => {
          if (!btn.classList.contains('on') && !btn.classList.contains('active')) {
            btn.click();
          }
        });

        if (window.location.href.includes('8090g.cn')) {
          const dmBtn = document.querySelector('.dplayer-danmaku-switch');
          if (dmBtn && dmBtn.style.opacity !== '1') {
            dmBtn.click();
          }
        }
      }, 3000);
    ''');
  }

  Future<void> _toggleDanmaku() async {
    setState(() => _isDanmakuEnabled = !_isDanmakuEnabled);

    await _controller.runJavaScript('''
      const danmakuButtons = document.querySelectorAll('[aria-label*="弹幕"], [title*="弹幕"], .danmaku-switch, .dm-switch');
      danmakuButtons.forEach(btn => btn.click());
    ''');
  }

  void _switchInterface() {
    setState(() {
      _currentInterfaceIndex = (_currentInterfaceIndex + 1) % AppConstants.parseInterfaces.length;
      _isLoading = true;
    });

    _controller.loadRequest(
      Uri.parse('${AppConstants.parseInterfaces[_currentInterfaceIndex]}${widget.episodes.isNotEmpty ? widget.episodes[_currentEpisodeIndex].url : widget.videoUrl}'),
    );
  }

  void _previousEpisode() {
    if (_currentEpisodeIndex > 0) {
      _savePlayHistory();
      setState(() {
        _currentEpisodeIndex--;
        _isLoading = true;
        _startTime = DateTime.now();
      });
      _controller.loadRequest(
        Uri.parse('${AppConstants.parseInterfaces[_currentInterfaceIndex]}${widget.episodes[_currentEpisodeIndex].url}'),
      );
    }
  }

  void _nextEpisode() {
    if (_currentEpisodeIndex < widget.episodes.length - 1) {
      _savePlayHistory();
      setState(() {
        _currentEpisodeIndex++;
        _isLoading = true;
        _startTime = DateTime.now();
      });
      _controller.loadRequest(
        Uri.parse('${AppConstants.parseInterfaces[_currentInterfaceIndex]}${widget.episodes[_currentEpisodeIndex].url}'),
      );
    }
  }

  void _checkVideoEnd() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _checkVideoEnd();
      }
    });
  }

  void _startProgressTimer() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _savePlayHistory();
        _startProgressTimer();
      }
    });
  }

  Future<void> _savePlayHistory() async {
    final watchDuration = DateTime.now().difference(_startTime);

    await _storageService.addPlayHistory(PlayHistory(
      title: widget.searchResult.title,
      cover: widget.searchResult.cover,
      videoUrl: widget.searchResult.url,
      platform: widget.searchResult.platform,
      lastEpisodeIndex: _currentEpisodeIndex,
      playProgressSeconds: watchDuration.inSeconds,
      watchTime: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _savePlayHistory();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.episodes.isNotEmpty
              ? '${widget.videoTitle} - 第${_currentEpisodeIndex+1}集'
              : widget.videoTitle),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _savePlayHistory();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isAutoPlay ? Icons.play_circle : Icons.play_circle_outline,
                color: _isAutoPlay ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() => _isAutoPlay = !_isAutoPlay);
              },
              tooltip: _isAutoPlay ? '关闭自动连播' : '开启自动连播',
            ),
            IconButton(
              icon: Icon(
                _isDanmakuEnabled ? Icons.subtitles : Icons.subtitles_off,
                color: _isDanmakuEnabled ? Colors.blue : Colors.grey,
              ),
              onPressed: _toggleDanmaku,
              tooltip: '弹幕开关',
            ),
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
              onSelected: (index) {
                setState(() => _currentInterfaceIndex = index);
                _controller.loadRequest(
                  Uri.parse('${AppConstants.parseInterfaces[index]}${widget.episodes.isNotEmpty ? widget.episodes[_currentEpisodeIndex].url : widget.videoUrl}'),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            if (widget.episodes.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentEpisodeIndex > 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: _previousEpisode,
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                    if (_currentEpisodeIndex < widget.episodes.length - 1)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: _nextEpisode,
                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}