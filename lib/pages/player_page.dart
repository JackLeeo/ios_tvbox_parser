import 'package:flutter/material.dart';
import 'package:hls_proplayer/hls_proplayer.dart';
import '../utils/constants.dart';

class PlayerPage extends StatefulWidget {
  final String keyword;

  const PlayerPage({super.key, required this.keyword});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  int _currentInterfaceIndex = 0;
  String _currentParseUrl = '';
  bool _isLoading = true;
  late HlsPlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _buildParseUrl();
  }

  void _buildParseUrl() {
    final parseBase = AppConstants.parseInterfaces[_currentInterfaceIndex];
    setState(() {
      _currentParseUrl = '$parseBase${Uri.encodeComponent(widget.keyword)}';
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
        title: Text(widget.keyword),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
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
      body: _currentParseUrl.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                showFullscreen: true,
              ),
              placeholderBuilder: (ctx) => const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
              bufferingIndicatorBuilder: (ctx) => const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
    );
  }
}
