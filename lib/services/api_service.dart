import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/source.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<List<VideoItem>> getHomeList(SiteRule site, {int page = 1}) async {
    try {
      final url = '${site.api}?ac=videolist&pg=$page';
      final response = await _dio.get(url, options: Options(headers: site.headers));
      if (response.data['code'] == 1) {
        final list = response.data['list'] as List;
        return list.map((e) => VideoItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<VideoItem>> search(SiteRule site, String keyword) async {
    try {
      final url = site.searchUrl ?? '${site.api}?ac=videolist&wd=$keyword';
      final response = await _dio.get(url, options: Options(headers: site.headers));
      if (response.data['code'] == 1) {
        final list = response.data['list'] as List;
        return list.map((e) => VideoItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Episode>> getEpisodes(SiteRule site, String videoId) async {
    try {
      final url = '${site.api}?ac=videolist&ids=$videoId';
      final response = await _dio.get(url, options: Options(headers: site.headers));
      if (response.data['code'] == 1 && response.data['list'].isNotEmpty) {
        final vod = response.data['list'][0];
        final playList = vod['vod_play_list'] as Map<String, dynamic>;
        final List<Episode> episodes = [];
        playList.forEach((source, urls) {
          final parts = urls.split('#');
          for (var part in parts) {
            final pair = part.split('\$');
            if (pair.length == 2) {
              episodes.add(Episode(name: pair[0], url: pair[1]));
            }
          }
        });
        return episodes;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
