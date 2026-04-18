import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';
import '../utils/extensions.dart';

class SourceParser {
  final Dio _dio = Dio();

  /// 解析配置内容（支持 URL、JSON 字符串、Base64，强力清理杂质）
  Future<SourceConfig> parseSource(String input) async {
    String jsonString;

    // 1. 如果是网络 URL
    if (input.startsWith('http://') || input.startsWith('https://')) {
      final response = await _dio.get(input);
      if (response.statusCode != 200) {
        throw Exception('网络请求失败');
      }
      jsonString = response.data;
    } else {
      // 2. 本地内容：先尝试 Base64 解码，再尝试提取 JSON
      String cleaned = input;

      // 如果包含 JFIF（图片），提取并清理 Base64 部分
      if (cleaned.contains('JFIF')) {
        // 【核心修改点】强力清洗：只保留 Base64 合法字符
        cleaned = _extractCleanBase64(cleaned);
      }

      // 尝试 Base64 解码
      if (cleaned.isBase64) {
        try {
          final bytes = base64.decode(cleaned);
          jsonString = utf8.decode(bytes);
        } catch (e) {
          // Base64 解码失败，可能是纯 JSON 字符串
          jsonString = _extractJson(cleaned);
        }
      } else {
        // 不是 Base64，直接提取 JSON
        jsonString = _extractJson(cleaned);
      }
    }

    // 最终解析 JSON
    try {
      final json = jsonDecode(jsonString);
      return SourceConfig.fromJson(json);
    } catch (e) {
      throw Exception('JSON 解析失败，请检查内容格式: $e');
    }
  }

  /// 强力提取并清理 Base64 字符串（去除所有非 Base64 字符）
  String _extractCleanBase64(String raw) {
    // 1. 找到 Base64 可能的起始位置（通常是 '{' 的 Base64 编码 'eyJ' 或类似结构）
    // 我们使用正则表达式，直接匹配最长可能的 Base64 连续字符串
    final RegExp base64RegExp = RegExp(r'[A-Za-z0-9+/=]+');
    final matches = base64RegExp.allMatches(raw);

    if (matches.isEmpty) return raw;

    // 2. 拼接所有匹配的片段，并移除可能存在的空白符
    String result = matches.map((match) => match.group(0)).join();
    
    // 3. Base64 的长度必须是 4 的倍数，如果末尾有多余的 '=' 或不规整，这里做个截断修正
    int remainder = result.length % 4;
    if (remainder > 0) {
      result = result.substring(0, result.length - remainder);
    }

    return result;
  }

  /// 从字符串中提取 JSON 部分（从第一个 { 到最后一个 }）
  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || start >= end) {
      throw Exception('未找到有效的 JSON 内容');
    }
    return raw.substring(start, end + 1);
  }
}
