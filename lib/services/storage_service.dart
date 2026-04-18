import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/video.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== 配置源 ==========
  Future<void> saveSourceUrl(String url) async {
    await _prefs.setString(AppConstants.keySourceUrl, url);
  }

  String? getSourceUrl() {
    return _prefs.getString(AppConstants.keySourceUrl);
  }

  Future<void> saveSourceContent(String content) async {
    await _prefs.setString(AppConstants.keySourceContent, content);
  }

  String? getSourceContent() {
    return _prefs.getString(AppConstants.keySourceContent);
  }

  Future<void> clearSource() async {
    await _prefs.remove(AppConstants.keySourceUrl);
    await _prefs.remove(AppConstants.keySourceContent);
  }

  // ========== 收藏 ==========
  static const String _favoriteKey = 'favorites';

  List<VideoItem> getFavorites() {
    final String? jsonString = _prefs.getString(_favoriteKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => VideoItem.fromJson(e)).toList();
  }

  Future<void> addFavorite(VideoItem video) async {
    final favorites = getFavorites();
    if (favorites.any((v) => v.id == video.id)) return;
    favorites.insert(0, video);
    await _prefs.setString(_favoriteKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  Future<void> removeFavorite(String id) async {
    final favorites = getFavorites();
    favorites.removeWhere((v) => v.id == id);
    await _prefs.setString(_favoriteKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  bool isFavorite(String id) {
    return getFavorites().any((v) => v.id == id);
  }
}
