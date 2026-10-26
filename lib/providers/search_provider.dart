import 'package:flutter/foundation.dart';
import '../models/image_result.dart';
import '../models/search_result.dart';
import '../services/searxng_api.dart';
import '../services/storage_service.dart';

class SearchProvider extends ChangeNotifier {
  final SearxngApiService _apiService;
  final StorageService _storageService;

  SearchProvider({
    SearxngApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? SearxngApiService(),
        _storageService = storageService ?? StorageService();

  String _instanceUrl = SearxngApiService.defaultInstanceUrl;
  List<String> _searchHistory = [];
  List<SearchResult> _bookmarks = [];
  String _currentQuery = '';

  // Tab 0: Web ("general")
  List<SearchResult> _webResults = [];
  bool _isWebLoading = false;
  String? _webError;
  bool _hasWebFetched = false;

  // Tab 1: News ("news")
  List<SearchResult> _newsResults = [];
  bool _isNewsLoading = false;
  String? _newsError;
  bool _hasNewsFetched = false;

  // Tab 2: Images ("images")
  List<ImageResult> _imageResults = [];
  bool _isImagesLoading = false;
  String? _imagesError;
  bool _hasImagesFetched = false;

  bool _isInitialized = false;

  // Getters
  String get instanceUrl => _instanceUrl;
  List<String> get searchHistory => _searchHistory;
  List<SearchResult> get bookmarks => _bookmarks;
  String get currentQuery => _currentQuery;
  bool get isInitialized => _isInitialized;

  List<SearchResult> get webResults => _webResults;
  bool get isWebLoading => _isWebLoading;
  String? get webError => _webError;
  bool get hasWebFetched => _hasWebFetched;

  List<SearchResult> get newsResults => _newsResults;
  bool get isNewsLoading => _isNewsLoading;
  String? get newsError => _newsError;
  bool get hasNewsFetched => _hasNewsFetched;

  List<ImageResult> get imageResults => _imageResults;
  bool get isImagesLoading => _isImagesLoading;
  String? get imagesError => _imagesError;
  bool get hasImagesFetched => _hasImagesFetched;

  /// Loads stored Instance URL, Search History, and Bookmarks on launch.
  Future<void> init() async {
    _instanceUrl = await _storageService.getInstanceUrl();
    _searchHistory = await _storageService.getSearchHistory();
    _bookmarks = await _storageService.getBookmarks();
    _isInitialized = true;
    notifyListeners();
  }

  /// Sets and validates the SearXNG instance URL.
  Future<String?> setInstanceUrl(String url) async {
    final validationError = SearxngApiService.validateInstanceUrl(url);
    if (validationError != null) {
      return validationError;
    }

    final cleanUrl = SearxngApiService.normalizeInstanceUrl(url);
    await _storageService.saveInstanceUrl(cleanUrl);
    _instanceUrl = cleanUrl;
    notifyListeners();
    return null;
  }

  /// Resets instance URL to default http://localhost:8080.
  Future<void> resetInstanceUrl() async {
    await _storageService.resetInstanceUrl();
    _instanceUrl = SearxngApiService.defaultInstanceUrl;
    notifyListeners();
  }

  /// Initiates a new search query, resetting tab caches and fetching initial tab.
  Future<void> search(String query, {int initialTab = 0}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _currentQuery = cleanQuery;

    // Save query to history
    _searchHistory = await _storageService.addSearchQuery(cleanQuery);

    // Reset tab caches
    _webResults = [];
    _isWebLoading = false;
    _webError = null;
    _hasWebFetched = false;

    _newsResults = [];
    _isNewsLoading = false;
    _newsError = null;
    _hasNewsFetched = false;

    _imageResults = [];
    _isImagesLoading = false;
    _imagesError = null;
    _hasImagesFetched = false;

    notifyListeners();

    // Load initial active tab
    await ensureTabLoaded(initialTab);
  }

  /// Lazy fetches results for the given tab index (0=All, 1=News, 2=Images) if not already fetched.
  Future<void> ensureTabLoaded(int tabIndex) async {
    if (_currentQuery.isEmpty) return;

    if (tabIndex == 0) {
      if (!_hasWebFetched && !_isWebLoading) {
        await _fetchWeb();
      }
    } else if (tabIndex == 1) {
      if (!_hasNewsFetched && !_isNewsLoading) {
        await _fetchNews();
      }
    } else if (tabIndex == 2) {
      if (!_hasImagesFetched && !_isImagesLoading) {
        await _fetchImages();
      }
    }
  }

  /// Retries fetch for the specified tab index.
  Future<void> retryTabSearch(int tabIndex) async {
    if (_currentQuery.isEmpty) return;

    if (tabIndex == 0) {
      _hasWebFetched = false;
      await _fetchWeb();
    } else if (tabIndex == 1) {
      _hasNewsFetched = false;
      await _fetchNews();
    } else if (tabIndex == 2) {
      _hasImagesFetched = false;
      await _fetchImages();
    }
  }

  Future<void> _fetchWeb() async {
    _isWebLoading = true;
    _webError = null;
    notifyListeners();

    try {
      _webResults = await _apiService.search(
        query: _currentQuery,
        instanceUrl: _instanceUrl,
        category: 'general',
      );
      _webError = null;
    } on SearxngApiException catch (e) {
      _webError = e.message;
      _webResults = [];
    } catch (e) {
      _webError = 'An unexpected error occurred: ${e.toString()}';
      _webResults = [];
    } finally {
      _isWebLoading = false;
      _hasWebFetched = true;
      notifyListeners();
    }
  }

  Future<void> _fetchNews() async {
    _isNewsLoading = true;
    _newsError = null;
    notifyListeners();

    try {
      _newsResults = await _apiService.search(
        query: _currentQuery,
        instanceUrl: _instanceUrl,
        category: 'news',
      );
      _newsError = null;
    } on SearxngApiException catch (e) {
      _newsError = e.message;
      _newsResults = [];
    } catch (e) {
      _newsError = 'An unexpected error occurred: ${e.toString()}';
      _newsResults = [];
    } finally {
      _isNewsLoading = false;
      _hasNewsFetched = true;
      notifyListeners();
    }
  }

  Future<void> _fetchImages() async {
    _isImagesLoading = true;
    _imagesError = null;
    notifyListeners();

    try {
      _imageResults = await _apiService.searchImages(
        query: _currentQuery,
        instanceUrl: _instanceUrl,
      );
      _imagesError = null;
    } on SearxngApiException catch (e) {
      _imagesError = e.message;
      _imageResults = [];
    } catch (e) {
      _imagesError = 'An unexpected error occurred: ${e.toString()}';
      _imageResults = [];
    } finally {
      _isImagesLoading = false;
      _hasImagesFetched = true;
      notifyListeners();
    }
  }

  // History management
  Future<void> removeFromHistory(String query) async {
    _searchHistory = await _storageService.removeSearchQuery(query);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = [];
    notifyListeners();
  }

  // Bookmark management
  bool isBookmarked(SearchResult item) {
    return _bookmarks.any((b) => b.url == item.url);
  }

  Future<void> toggleBookmark(SearchResult item) async {
    if (isBookmarked(item)) {
      _bookmarks.removeWhere((b) => b.url == item.url);
    } else {
      _bookmarks.add(item);
    }
    await _storageService.saveBookmarks(_bookmarks);
    notifyListeners();
  }

  Future<void> removeBookmark(SearchResult item) async {
    _bookmarks.removeWhere((b) => b.url == item.url);
    await _storageService.saveBookmarks(_bookmarks);
    notifyListeners();
  }

  Future<void> clearBookmarks() async {
    await _storageService.clearBookmarks();
    _bookmarks = [];
    notifyListeners();
  }
}
