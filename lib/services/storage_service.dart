import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';
import 'searxng_api.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _secureInstanceUrlKey = 'searxng_instance_url';
  static const String _fallbackInstanceUrlKey = 'searxng_instance_url_fallback';
  static const String _historyKey = 'search_history';
  static const String _bookmarksKey = 'bookmarks_list';

  /// Retrieves SearXNG instance URL, defaulting to http://localhost:8080.
  Future<String> getInstanceUrl() async {
    try {
      final url = await _secureStorage.read(key: _secureInstanceUrlKey);
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_fallbackInstanceUrlKey);
    if (url != null && url.isNotEmpty) {
      return url;
    }

    return SearxngApiService.defaultInstanceUrl;
  }

  /// Saves SearXNG instance URL.
  Future<void> saveInstanceUrl(String url) async {
    final cleanUrl = SearxngApiService.normalizeInstanceUrl(url);
    final prefs = await SharedPreferences.getInstance();

    try {
      await _secureStorage.write(key: _secureInstanceUrlKey, value: cleanUrl);
      await prefs.remove(_fallbackInstanceUrlKey);
    } catch (_) {
      await prefs.setString(_fallbackInstanceUrlKey, cleanUrl);
    }
  }

  /// Resets instance URL to default (http://localhost:8080).
  Future<void> resetInstanceUrl() async {
    await saveInstanceUrl(SearxngApiService.defaultInstanceUrl);
  }

  /// Gets search history (up to 10 items).
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  /// Adds a query to search history, keeping only the last 10 unique entries.
  Future<List<String>> addSearchQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getSearchHistory();
    }

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];

    history.removeWhere((item) => item.toLowerCase() == cleanQuery.toLowerCase());
    history.insert(0, cleanQuery);

    if (history.length > 10) {
      history.removeRange(10, history.length);
    }

    await prefs.setStringList(_historyKey, history);
    return history;
  }

  /// Removes a single query from search history.
  Future<List<String>> removeSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];

    history.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
    await prefs.setStringList(_historyKey, history);
    return history;
  }

  /// Clears search history.
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Retrieves saved bookmarks as JSON.
  Future<List<SearchResult>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_bookmarksKey);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(rawJson);
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map((item) => SearchResult.fromJson(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the list of bookmarks as JSON.
  Future<void> saveBookmarks(List<SearchResult> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_bookmarksKey, jsonEncode(jsonList));
  }

  /// Clears all bookmarks.
  Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarksKey);
  }
}
