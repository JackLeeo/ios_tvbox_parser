import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/source.dart';
import 'source_parser.dart';

class ConfigService {
  static const String _configKey = 'tvbox_config';

  /// 保存配置字符串（可以是URL或Base64编码的JSON）
  Future<void> saveConfig(String input) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, input);
  }

  /// 获取保存的配置字符串
  Future<String?> getConfigString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_configKey);
  }

  /// 解析配置字符串为 SourceConfig
  Future<SourceConfig?> loadConfig() async {
    final input = await getConfigString();
    if (input == null || input.isEmpty) return null;

    // 判断是否为URL（简单判断以 http:// 或 https:// 开头）
    if (input.startsWith('http://') || input.startsWith('https://')) {
      try {
        return await SourceParser().loadSourceFromUrl(input);
      } catch (e) {
        // 如果网络加载失败，返回 null
        return null;
      }
    } else {
      // 尝试 Base64 解码
      try {
        final jsonString = utf8.decode(base64Decode(input));
        return SourceParser().loadSourceFromJson(jsonString);
      } catch (e) {
        // 解码失败，尝试直接作为 JSON 解析
        try {
          return SourceParser().loadSourceFromJson(input);
        } catch (e) {
          return null;
        }
      }
    }
  }

  /// 清除配置
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }
}
