import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';
import '../utils/extensions.dart';

class SourceParser {
  final Dio _dio = Dio();

  /// 解析配置内容（支持 URL、JSON 字符串、Base64）
  Future<SourceConfig> parseSource(String input) async {
    String jsonString;

    if (input.startsWith('http://') || input.startsWith('https://')) {
      // 从网络加载
      final response = await _dio.get(input);
      if (response.statusCode != 200) {
        throw Exception('网络请求失败');
      }
      jsonString = response.data;
    } else if (input.isBase64) {
      // Base64 解码
      try {
        final bytes = base64.decode(input);
        jsonString = utf8.decode(bytes);
      } catch (e) {
        throw Exception('Base64 解码失败');
      }
    } else {
      // 直接作为 JSON 字符串
      jsonString = input;
    }

    final json = jsonDecode(jsonString);
    return SourceConfig.fromJson(json);
  }
}
