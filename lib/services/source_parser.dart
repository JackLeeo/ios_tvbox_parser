import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';
import '../utils/extensions.dart';

class SourceParser {
  final Dio _dio = Dio();

  /// 解析配置内容（支持 URL、JSON 字符串、Base64，智能清理杂质）
  Future<SourceConfig> parseSource(String input) async {
    String jsonString;

    // 1. 网络 URL
    if (input.startsWith('http://') || input.startsWith('https://')) {
      final response = await _dio.get(input);
      if (response.statusCode != 200) {
        throw Exception('网络请求失败');
      }
      jsonString = response.data;
    } else {
      String cleaned = input;

      // 2. 正向提取所有 Base64 合法字符
      cleaned = _extractCleanBase64(cleaned);

      // 3. 清理所有空白字符
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');

      // 4. ✅ 正确补齐 Base64（只在末尾补 =）
      final remainder = cleaned.length % 4;
      if (remainder != 0) {
        cleaned += '=' * (4 - remainder);
      }

      // 5. 尝试 Base64 解码
      if (cleaned.isBase64) {
        try {
          final bytes = base64.decode(cleaned);
          try {
            jsonString = utf8.decode(bytes);
          } on FormatException {
            jsonString = String.fromCharCodes(bytes);
          }
        } catch (e) {
          jsonString = _extractJson(cleaned);
        }
      } else {
        jsonString = _extractJson(cleaned);
      }
    }

    // 6. 修复最常见的 JSON 格式问题（只修致命错误）
    jsonString = _repairJson(jsonString);

    // 7. 最终解析 JSON
    try {
      final json = jsonDecode(jsonString);
      return SourceConfig.fromJson(json);
    } catch (e) {
      throw Exception('JSON 解析失败，请检查内容格式: $e');
    }
  }

  /// 正向提取所有 Base64 合法字符（A-Za-z0-9+/=）
  String _extractCleanBase64(String raw) {
    final regExp = RegExp(r'[A-Za-z0-9+/=]+');
    final matches = regExp.allMatches(raw);
    if (matches.isEmpty) return raw;
    return matches.map((m) => m.group(0)).join();
  }

  /// 从字符串中提取 JSON 部分（支持对象和数组格式）
  String _extractJson(String raw) {
    int start = raw.indexOf('{');
    int end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || start >= end) {
      start = raw.indexOf('[');
      end = raw.lastIndexOf(']');
      if (start == -1 || end == -1 || start >= end) {
        throw Exception('未找到有效的 JSON 内容');
      }
    }
    return raw.substring(start, end + 1);
  }

  /// 修复最常见的 JSON 语法错误（保守策略）
  String _repairJson(String json) {
    // 只修复一个最致命的问题：对象/数组末尾的多余逗号
    return json.replaceAllMapped(
      RegExp(r',(\s*[}\]])'),
      (match) => match.group(1)!,
    );
  }
}
