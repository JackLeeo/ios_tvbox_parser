class AppConstants {
  // 解析接口列表（可以自行增减）
  static const List<String> parseInterfaces = [
    "https://bd.jx.cn/?url=",          // 冰豆
       "https://jx.yparse.com/index.php?url=",
    "https://api.qianqi.net/vip/?url=",
  ];

  static const List<String> interfaceNames = [
    "冰豆", "云析", "千奇"
  ];

  static const String userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1";
}
