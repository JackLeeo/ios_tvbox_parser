class AppConstants {
  // 默认TVBox配置源（你的乱码解码后的URL）
  static const String defaultSourceUrl = 
      'https://gh-proxy.com/https://raw.githubusercontent.com/fantaiying7/EXT/refs/heads/main/drpy2.min.js'; // 稍后教你解码

  // 解析接口备用
  static const List<String> parseInterfaces = [
    "https://bd.jx.cn/?url=",
    "https://www.8090g.cn/?url=",
    "https://jx.yparse.com/index.php?url=",
  ];

  static const List<String> interfaceNames = ["冰豆", "8090", "云析"];
}
