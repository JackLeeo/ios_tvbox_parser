class AppConstants {
  // 视频解析接口（用于将平台页面地址转换为可直接播放的视频流）
  static const List<String> parseInterfaces = [
    "https://www.8090g.cn/?url=",
    "https://jx.yparse.com/index.php?url=",
    "https://api.qianqi.net/vip/?url=",
    "https://www.ckplayer.vip/jiexi/?url=",
    "https://jx.m3u8.tv/jiexi/?url=",
    "https://www.playm3u8.cn/jiexi.php?url=",
    "https://jx.xmflv.com/?url=",
    "https://jx.aidouer.net/?url=",
  ];

  static const List<String> interfaceNames = [
    "8090", "云析", "冰豆", "CK", "M3U8", "PM", "虾米", "爱豆"
  ];

  static const String userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1";
}
