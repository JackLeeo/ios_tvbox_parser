import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class NodeParserService {
  static final NodeParserService _instance = NodeParserService._internal();
  factory NodeParserService() => _instance;
  NodeParserService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 30),
    baseUrl: 'http://127.0.0.1:8765',
  ));

  bool _ready = false;
  final _readyCompleter = Completer<void>();
  final _methodChannel = const MethodChannel('com.example.iosTvboxParser/nodejs');

  Future<void> init() async {
    if (_readyCompleter.isCompleted) return;

    try {
      await _methodChannel.invokeMethod('start');
    } catch (e) {
      print('启动 Node.js 失败: $e');
      return;
    }

    // 轮询等待 HTTP 服务就绪
    int retries = 0;
    while (retries < 40) {
      try {
        final response = await _dio.get('/');
        if (response.statusCode == 200 || response.statusCode == 404) {
          _ready = true;
          _readyCompleter.complete();
          print('Node.js HTTP 服务已就绪');
          return;
        }
      } catch (e) {
        // 忽略连接错误，继续重试
      }
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }
    print('Node.js HTTP 服务启动超时');
  }

  Future<Map<String, dynamic>> _sendRequest(String action, Map<String, dynamic> payload) async {
    if (!_ready) {
      throw Exception('Node.js 服务未就绪');
    }
    final response = await _dio.post('/parse', data: {
      'action': action,
      'payload': payload,
    });
    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 200) {
        return {'data': data['data']};
      } else {
        throw Exception(data['error'] ?? '未知错误');
      }
    } else {
      throw Exception('HTTP 错误: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getHome(String rule, {int page = 1}) =>
      _sendRequest('home', {'rule': rule, 'page': page});

  Future<Map<String, dynamic>> search(String rule, String keyword, {int page = 1}) =>
      _sendRequest('search', {'rule': rule, 'keyword': keyword, 'page': page});

  Future<Map<String, dynamic>> getDetail(String rule, String url) =>
      _sendRequest('detail', {'rule': rule, 'url': url});

  Future<Map<String, dynamic>> getPlayUrl(String rule, String flag, String id) =>
      _sendRequest('play', {'rule': rule, 'flag': flag, 'id': id});

  void dispose() {}
}
