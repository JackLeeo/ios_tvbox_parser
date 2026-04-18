import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/video.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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
