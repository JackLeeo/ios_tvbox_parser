import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/search_result.dart';
import '../models/storage_models.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _historyKey = 'video_play_history';

  List<PlayHistory> getPlayHistory() {
    final String? jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PlayHistory.fromJson(json)).toList();
  }

  Future<void> addPlayHistory(PlayHistory history) async {
    final List<PlayHistory> historyList = getPlayHistory();
    historyList.removeWhere((item) => item.videoUrl == history.videoUrl);
    historyList.insert(0, history);

    if (historyList.length > 50) {
      historyList.removeRange(50, historyList.length);
    }

    await _prefs.setString(_historyKey, json.encode(historyList.map((e) => e.toJson()).toList()));
  }

  Future<void> deletePlayHistory(String videoUrl) async {
    final List<PlayHistory> historyList = getPlayHistory();
    historyList.removeWhere((item) => item.videoUrl == videoUrl);
    await _prefs.setString(_historyKey, json.encode(historyList.map((e) => e.toJson()).toList()));
  }

  Future<void> clearAllHistory() async {
    await _prefs.remove(_historyKey);
  }

  static const String _favoriteKey = 'video_favorites';

  List<SearchResult> getFavorites() {
    final String? jsonString = _prefs.getString(_favoriteKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => SearchResult.fromJson(json)).toList();
  }

  Future<void> addFavorite(SearchResult video) async {
    final List<SearchResult> favorites = getFavorites();
    if (favorites.any((item) => item.url == video.url)) return;

    favorites.insert(0, video);
    await _prefs.setString(_favoriteKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  Future<void> removeFavorite(String videoUrl) async {
    final List<SearchResult> favorites = getFavorites();
    favorites.removeWhere((item) => item.url == videoUrl);
    await _prefs.setString(_favoriteKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  bool isFavorite(String videoUrl) {
    final List<SearchResult> favorites = getFavorites();
    return favorites.any((item) => item.url == videoUrl);
  }

  static const String _progressKey = 'video_progress_';

  Future<void> saveVideoProgress(String videoId, int seconds) async {
    await _prefs.setInt('$_progressKey$videoId', seconds);
  }

  int getVideoProgress(String videoId) {
    return _prefs.getInt('$_progressKey$videoId') ?? 0;
  }
}