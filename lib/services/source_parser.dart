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

      // 2. ✅ 修复：专门处理 JFIF + Base64 的情况
      if (cleaned.contains('JFIF')) {
        // 找到 Base64 数据的起始位置（JSON 的 Base64 编码通常以 eyJ 开头）
        int base64Start = cleaned.indexOf('eyJ');
        if (base64Start == -1) {
          // 如果找不到 eyJ，尝试找其他可能的起始标记
          base64Start = cleaned.indexOf('W3s'); // [{
        }
        if (base64Start != -1) {
          cleaned = cleaned.substring(base64Start);
        }
        
        // 清理所有非 Base64 字符
        cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      }

      // 3. 确保 Base64 长度是 4 的倍数（✅ 正确方式）
      final remainder = cleaned.length % 4;
      if (remainder != 0) {
        cleaned += '=' * (4 - remainder);
      }

      // 4. 尝试 Base64 解码
      if (cleaned.isBase64) {
        try {
          final bytes = base64.decode(cleaned);
          try {
            jsonString = utf8.decode(bytes);
          } on FormatException {
            jsonString = String.fromCharCodes(bytes);
          }
        } catch (e) {
          // Base64 解码失败，尝试直接提取 JSON
          jsonString = _extractJson(cleaned);
        }
      } else {
        jsonString = _extractJson(cleaned);
      }
    }

    // 5. 修复常见的 JSON 格式问题
    jsonString = _repairJson(jsonString);

    // 6. 最终解析 JSON
    try {
      final json = jsonDecode(jsonString);
      return SourceConfig.fromJson(json);
    } catch (e) {
      throw Exception('JSON 解析失败，请检查内容格式: $e\nJSON 预览: ${jsonString.substring(0, 100)}...');
    }
  }

  /// ✅ 从字符串中提取 JSON 部分（支持对象和数组格式）
  String _extractJson(String raw) {
    // 尝试找到 JSON 对象的开始和结束
    int start = raw.indexOf('{');
    int end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && start < end) {
      return raw.substring(start, end + 1);
    }
    
    // 尝试找到 JSON 数组的开始和结束
    start = raw.indexOf('[');
    end = raw.lastIndexOf(']');
    if (start != -1 && end != -1 && start < end) {
      return raw.substring(start, end + 1);
    }
    
    throw Exception('未找到有效的 JSON 内容');
  }

  /// 修复常见的 JSON 语法错误（保守策略）
  String _repairJson(String json) {
    // 只修复一个最致命的问题：对象/数组末尾多余逗号
    return json.replaceAllMapped(
      RegExp(r',(\s*[}\]])'),
      (match) => match.group(1)!,
    );
  }
}
