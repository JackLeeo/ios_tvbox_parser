import 'dart:async';
import 'dart:convert';
import 'package:node_flutter/node_flutter.dart';

class NodeParserService {
  static final NodeParserService _instance = NodeParserService._internal();
  factory NodeParserService() => _instance;
  NodeParserService._internal();

  final _readyCompleter = Completer<void>();
  final _pendingRequests = <String, Completer<Map<String, dynamic>>>{};
  StreamSubscription? _subscription;

  Future<void> init() async {
    if (_readyCompleter.isCompleted) return;

    // 启动 Node.js 运行时，自动加载 nodejs-project/main.js
    await Nodejs.start();

    _subscription = Nodejs.onMessageReceived.listen((event) {
      final channel = event['channelName'] as String?;
      final message = event['message'];

      if (channel == 'node_ready') {
        _readyCompleter.complete();
      } else if (channel == 'parse_result') {
        final data = message is String ? jsonDecode(message) : message as Map<String, dynamic>;
        final requestId = data['requestId'] as String;
        _pendingRequests[requestId]?.complete(data);
        _pendingRequests.remove(requestId);
      } else if (channel == 'parse_error') {
        final error = message is String ? jsonDecode(message) : message as Map<String, dynamic>;
        final requestId = error['requestId'] as String;
        _pendingRequests[requestId]?.completeError(error['error']);
        _pendingRequests.remove(requestId);
      }
    });

    await _readyCompleter.future.timeout(const Duration(seconds: 10));
  }

  Future<Map<String, dynamic>> _sendRequest(String action, Map<String, dynamic> payload) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final request = jsonEncode({'requestId': requestId, 'action': action, 'payload': payload});

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    Nodejs.sendMessage('parse', request);

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Node.js 解析超时'),
    );
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
    _subscription?.cancel();
    Nodejs.stop();
  }
}
