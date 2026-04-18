import '../utils/constants.dart';

class PlayerService {
  static String getParseUrl(String videoUrl, {int parserIndex = 0}) {
    final base = AppConstants.parseInterfaces[parserIndex];
    return '$base${Uri.encodeComponent(videoUrl)}';
  }
}
