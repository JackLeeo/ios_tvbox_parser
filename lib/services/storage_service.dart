import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/video_model.dart';
import '../models/storage_models.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 播放历史 ====================
  static const String _historyKey = 'video_play_history';

  List<PlayHistory> getPlayHistory() {
    final String? jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PlayHistory.fromJson(json)).toList();
  }

  Future<void> addPlayHistory(PlayHistory history) async {
    final List<PlayHistory> historyList = getPlayHistory();
    historyList.removeWhere((item) => item.videoId == history.videoId);
    historyList.insert(0, history);
    
    if (historyList.length > 50) {
      historyList.removeRange(50, historyList.length);
    }
    
    await _prefs.setString(_historyKey, json.encode(historyList.map((e) => e.toJson()).toList()));
  }

  Future<void> deletePlayHistory(String videoId) async {
    final List<PlayHistory> historyList = getPlayHistory();
    historyList.removeWhere((item) => item.videoId == videoId);
    await _prefs.setString(_historyKey, json.encode(historyList.map((e) => e.toJson()).toList()));
  }

  Future<void> clearAllHistory() async {
    await _prefs.remove(_historyKey);
  }

  // ==================== 收藏功能 ====================
  static const String _favoriteKey = 'video_favorites';

  List<VideoItem> getFavorites() {
    final String? jsonString = _prefs.getString(_favoriteKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => VideoItem.fromJson(json)).toList();
  }

  Future<void> addFavorite(VideoItem video) async {
    final List<VideoItem> favorites = getFavorites();
    if (favorites.any((item) => item.id == video.id)) return;
    
    favorites.insert(0, video);
    await _prefs.setString(_favoriteKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  Future<void> removeFavorite(String videoId) async {
    final List<VideoItem> favorites = getFavorites();
    favorites.removeWhere((item) => item.id == videoId);
    await _prefs.setString(_favoriteKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  bool isFavorite(String videoId) {
    final List<VideoItem> favorites = getFavorites();
    return favorites.any((item) => item.id == videoId);
  }
}
