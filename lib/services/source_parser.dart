import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';
import '../utils/extensions.dart';

class SourceParser {
  final Dio _dio = Dio();

  /// 解析配置内容（支持 URL、JSON 字符串、Base64，智能清理杂质）
  Future<SourceConfig> parseSource(String input) async {
    // 1. 如果是网络 URL，先拉取内容，之后统一处理
    if (input.startsWith('http://') || input.startsWith('https://')) {
      final response = await _dio.get(input);
      if (response.statusCode != 200) {
        throw Exception('网络请求失败');
      }
      // 网络返回的内容也可能是带图片头/Base64的配置，统一交给后续逻辑处理
      input = response.data;
    }

    // 2. 统一处理所有内容（本地输入/网络返回的内容走完全一致的流程）
    String cleaned = input;

    // 若包含 JFIF（图片乱码），精准定位 Base64 配置段
    if (cleaned.contains('JFIF')) {
      int base64Start = cleaned.length;

      // 优先查找常见的 JSON Base64 特征开头
      const markers = ['eyJ', 'W3s', 'e3s'];
      for (final marker in markers) {
        final index = cleaned.indexOf(marker);
        if (index != -1 && index < base64Start) {
          base64Start = index;
        }
      }

      // 若未找到特征头，回退到逆向扫描第一个非 Base64 字符
      if (base64Start == cleaned.length) {
        for (int i = cleaned.length - 1; i >= 0; i--) {
          if (!_isBase64Char(cleaned.codeUnitAt(i))) {
            base64Start = i + 1;
            break;
          }
        }
      }

      cleaned = cleaned.substring(base64Start);
    }

    // 3. 清理所有空白字符（换行、空格等格式符）
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');

    // 4. 确保 Base64 长度是 4 的倍数（自动补齐缺失的填充符 =）
    final remainder = cleaned.length % 4;
    if (remainder != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - remainder), '=');
    }

    // 5. 尝试 Base64 解码
    String jsonString;
    if (cleaned.isBase64) {
      try {
        final bytes = base64.decode(cleaned);
        try {
          jsonString = utf8.decode(bytes);
        } on FormatException {
          // UTF8 解码失败，回退到 Latin1 尽可能还原内容
          jsonString = String.fromCharCodes(bytes);
        }
      } catch (e) {
        // Base64 解码彻底失败，回退到提取 JSON 原文
        jsonString = _extractJson(cleaned);
      }
    } else {
      // 不是 Base64，直接提取 JSON
      jsonString = _extractJson(cleaned);
    }

    // 6. 最终解析 JSON
    try {
      final json = jsonDecode(jsonString);
      return SourceConfig.fromJson(json);
    } catch (e) {
      throw Exception('JSON 解析失败，请检查内容格式: $e');
    }
  }

  /// 判断字符是否为 Base64 合法字符
  static bool _isBase64Char(int codeUnit) {
    return (codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
           (codeUnit >= 0x61 && codeUnit <= 0x7A) || // a-z
           (codeUnit >= 0x30 && codeUnit <= 0x39) || // 0-9
           codeUnit == 0x2B || // +
           codeUnit == 0x2F || // /
           codeUnit == 0x3D;   // =
  }

  /// 从字符串中提取 JSON 部分（同时支持对象和数组格式）
  String _extractJson(String raw) {
    // 优先尝试提取对象格式 JSON
    int start = raw.indexOf('{');
    int end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || start >= end) {
      // 回退到提取数组格式 JSON
      start = raw.indexOf('[');
      end = raw.lastIndexOf(']');
      if (start == -1 || end == -1 || start >= end) {
        throw Exception('未找到有效的 JSON 内容');
      }
    }
    return raw.substring(start, end + 1);
  }
}
