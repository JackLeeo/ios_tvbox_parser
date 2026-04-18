import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/source.dart';

class SourceParser {
  final Dio _dio = Dio();

  Future<SourceConfig> loadSource(String url) async {
    final response = await _dio.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.data);
      return SourceConfig.fromJson(json);
    }
    throw Exception('加载配置失败');
  }
}

// models/source.dart
class SourceConfig {
  final String name;
  final List<SiteRule> sites;

  SourceConfig({required this.name, required this.sites});

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      name: json['name'] ?? '',
      sites: (json['sites'] as List?)?.map((e) => SiteRule.fromJson(e)).toList() ?? [],
    );
  }
}

class SiteRule {
  final String key;
  final String name;
  final String api;
  final String? searchUrl;
  final Map<String, String>? headers;

  SiteRule({required this.key, required this.name, required this.api, this.searchUrl, this.headers});

  factory SiteRule.fromJson(Map<String, dynamic> json) {
    return SiteRule(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      api: json['api'] ?? '',
      searchUrl: json['searchUrl'],
      headers: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
    );
  }
}
