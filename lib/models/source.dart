import 'dart:convert';

class SourceConfig {
  final String name;
  final List<SiteRule> sites;

  SourceConfig({required this.name, required this.sites});

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      name: json['name']?.toString() ?? '',
      sites: (json['sites'] as List?)
              ?.map((e) => SiteRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SiteRule {
  final String key;
  final String name;
  final String api;
  final String? searchUrl;
  final Map<String, String>? headers;
  final int? playerType;
  final int? timeout;
  final int? type;
  final bool searchable;
  final bool quickSearch;
  final bool changeable;
  final Map<String, dynamic>? ext;
  final Map<String, dynamic>? style;

  SiteRule({
    required this.key,
    required this.name,
    required this.api,
    this.searchUrl,
    this.headers,
    this.playerType,
    this.timeout,
    this.type,
    this.searchable = true,
    this.quickSearch = false,
    this.changeable = false,
    this.ext,
    this.style,
  });

  factory SiteRule.fromJson(Map<String, dynamic> json) {
    // 安全转换数字字段
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // 安全转换布尔字段
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == '1' || v == 'true';
      }
      return false;
    }

    // 安全转换 Map 类型字段（ext、style、headers）
    Map<String, dynamic>? parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is String) {
        // 如果是字符串，尝试解析为 JSON，失败则包装为 {"raw": value}
        try {
          return jsonDecode(value);
        } catch (_) {
          return {'raw': value};
        }
      }
      return null;
    }

    return SiteRule(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      api: json['api']?.toString() ?? '',
      searchUrl: json['searchUrl']?.toString(),
      headers: parseMap(json['headers'])?.map((k, v) => MapEntry(k, v.toString())),
      playerType: parseInt(json['playerType']),
      timeout: parseInt(json['timeout']),
      type: parseInt(json['type']),
      searchable: parseBool(json['searchable']),
      quickSearch: parseBool(json['quickSearch']),
      changeable: parseBool(json['changeable']),
      ext: parseMap(json['ext']),
      style: parseMap(json['style']),
    );
  }
}

// 如果 jsonDecode 未导入，请在文件顶部添加 import 'dart:convert';
