import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';

class SourceParser {
  final Dio _dio = Dio();

  Future<SourceConfig> loadSource(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.data);
        return SourceConfig.fromJson(json);
      }
      throw Exception('加载配置失败');
    } catch (e) {
      throw Exception('加载配置失败: $e');
    }
  }
}
