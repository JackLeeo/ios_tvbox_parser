import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class NodeParserService {
  static final NodeParserService _instance = NodeParserService._internal();
  factory NodeParserService() => _instance;
  NodeParserService._internal();

  final _methodChannel = const MethodChannel('com.example.iosTvboxParser/nodejs');
  final _eventChannel = const EventChannel('com.example.iosTvboxParser/nodejs_events');
  final _readyCompleter = Completer<void>();
  final _pendingRequests = <String, Completer<Map<String, dynamic>>>{};
  StreamSubscription? _eventSubscription;

  Future<void> init() async {
    if (_readyCompleter.isCompleted) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final map = event as Map<dynamic, dynamic>;
      final channel = map['channel'] as String;
      final message = map['message'] as String;

      if (channel == 'node_ready') {
        _readyCompleter.complete();
      } else if (channel == 'parse_result') {
        final data = jsonDecode(message) as Map<String, dynamic>;
        final requestId = data['requestId'] as String;
        _pendingRequests[requestId]?.complete(data);
        _pendingRequests.remove(requestId);
      } else if (channel == 'parse_error') {
        final error = jsonDecode(message) as Map<String, dynamic>;
        final requestId = error['requestId'] as String;
        _pendingRequests[requestId]?.completeError(error['error']);
        _pendingRequests.remove(requestId);
      }
    });

    try {
      await _methodChannel.invokeMethod('start');
      await _readyCompleter.future.timeout(const Duration(seconds: 10));
      print('Node.js 引擎已就绪');
    } catch (e) {
      print('Node.js 启动失败: $e');
    }
  }

  Future<Map<String, dynamic>> _sendRequest(String action, Map<String, dynamic> payload) async {
    if (!_readyCompleter.isCompleted) {
      throw Exception('Node.js 未就绪');
    }
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final request = jsonEncode({'requestId': requestId, 'action': action, 'payload': payload});
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    await _methodChannel.invokeMethod('sendMessage', {'channel': 'parse', 'message': request});

    return completer.future.timeout(const Duration(seconds: 30));
  }

  Future<Map<String, dynamic>> getHome(String rule, {int page = 1}) =>
      _sendRequest('home', {'rule': rule, 'page': page});

  Future<Map<String, dynamic>> search(String rule, String keyword, {int page = 1}) =>
      _sendRequest('search', {'rule': rule, 'keyword': keyword, 'page': page});

  Future<Map<String, dynamic>> getDetail(String rule, String url) =>
      _sendRequest('detail', {'rule': rule, 'url': url});

  Future<Map<String, dynamic>> getPlayUrl(String rule, String flag, String id) =>
      _sendRequest('play', {'rule': rule, 'flag': flag, 'id': id});

  void dispose() {
    _eventSubscription?.cancel();
  }
}
