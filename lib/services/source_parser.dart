import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';

class SourceParser {
  final Dio _dio = Dio();

  Future<SourceConfig> loadSourceFromUrl(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return loadSourceFromJson(response.data);
      }
      throw Exception('加载配置失败');
    } catch (e) {
      throw Exception('加载配置失败: $e');
    }
  }

  SourceConfig loadSourceFromJson(String jsonString) {
    final json = jsonDecode(jsonString);
    return SourceConfig.fromJson(json);
  }
}
