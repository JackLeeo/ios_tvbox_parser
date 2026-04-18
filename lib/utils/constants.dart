class AppConstants {
  // 公共解析接口（备用）
  static const List<String> parseInterfaces = [
    "https://bd.jx.cn/?url=",
    "https://www.8090g.cn/?url=",
    "https://jx.yparse.com/index.php?url=",
  ];

  static const List<String> interfaceNames = ["冰豆", "8090", "云析"];

  // 存储键
  static const String keySourceUrl = 'tvbox_source_url';
  static const String keySourceContent = 'tvbox_source_content';

  // 内置默认配置源（备用，用户也可自定义）
  static const String defaultSourceJson = '''
{
  "name": "默认源",
  "sites": [
    {
      "key": "test",
      "name": "测试站点",
      "type": 1,
      "api": "csp_TestGuard",
      "searchable": 1,
      "quickSearch": 1,
      "changeable": 0,
      "ext": { "rule": "csp_TestGuard" }
    }
  ]
}
''';
}
