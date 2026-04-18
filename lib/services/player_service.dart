import '../utils/constants.dart';

class PlayerService {
  /// 根据视频播放页 URL 生成解析后的播放地址
  static String getParseUrl(String videoUrl, {int parserIndex = 0}) {
    final base = AppConstants.parseInterfaces[parserIndex];
    return '$base${Uri.encodeComponent(videoUrl)}';
  }
}
