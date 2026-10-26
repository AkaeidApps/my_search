import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/image_result.dart';
import '../models/search_result.dart';

class SearxngApiException implements Exception {
  final String message;
  final int? statusCode;

  SearxngApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SearxngApiService {
  final http.Client _client;

  SearxngApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String defaultInstanceUrl = 'http://localhost:8080';
  static const Duration _timeout = Duration(seconds: 15);

  /// Validates and normalizes SearXNG instance URL.
  static String normalizeInstanceUrl(String rawUrl) {
    var clean = rawUrl.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (clean.isEmpty) {
      return defaultInstanceUrl;
    }
    return clean;
  }

  /// Validates instance URL format. Returns error string if invalid, or null if valid.
  static String? validateInstanceUrl(String rawUrl) {
    final clean = normalizeInstanceUrl(rawUrl);
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      return 'Instance URL must start with http:// or https://';
    }
    final uri = Uri.tryParse(clean);
    if (uri == null || !uri.hasAuthority) {
      return 'Invalid URL format.';
    }
    return null;
  }

  /// Executes SearXNG Search API request.
  Future<List<SearchResult>> search({
    required String query,
    required String instanceUrl,
    required String category, // "general" or "news"
  }) async {
    final baseUrl = normalizeInstanceUrl(instanceUrl);
    final validationError = validateInstanceUrl(baseUrl);
    if (validationError != null) {
      throw SearxngApiException(validationError);
    }

    final uri = Uri.parse(
      '$baseUrl/search?q=${Uri.encodeComponent(query)}&categories=$category&format=json',
    );

    final response = await _makeGetRequest(uri);

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final resultsList = json['results'] as List<dynamic>?;
      if (resultsList == null) {
        return [];
      }

      return resultsList
          .whereType<Map<String, dynamic>>()
          .map((item) => SearchResult.fromSearxngJson(item))
          .toList();
    } catch (e) {
      if (e is SearxngApiException) rethrow;
      throw SearxngApiException('Failed to parse search results response.');
    }
  }

  /// Executes SearXNG Image Search API request.
  Future<List<ImageResult>> searchImages({
    required String query,
    required String instanceUrl,
  }) async {
    final baseUrl = normalizeInstanceUrl(instanceUrl);
    final validationError = validateInstanceUrl(baseUrl);
    if (validationError != null) {
      throw SearxngApiException(validationError);
    }

    final uri = Uri.parse(
      '$baseUrl/search?q=${Uri.encodeComponent(query)}&categories=images&format=json',
    );

    final response = await _makeGetRequest(uri);

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final resultsList = json['results'] as List<dynamic>?;
      if (resultsList == null) {
        return [];
      }

      return resultsList
          .whereType<Map<String, dynamic>>()
          .map((item) => ImageResult.fromSearxngJson(item))
          .toList();
    } catch (e) {
      if (e is SearxngApiException) rethrow;
      throw SearxngApiException('Failed to parse image search response.');
    }
  }

  /// Helper to send GET request with headers, timeout, and error handling.
  Future<http.Response> _makeGetRequest(Uri uri) async {
    final headers = {
      'Accept': 'application/json',
      'User-Agent': 'MySearch-Linux-Desktop/1.0',
    };

    try {
      final response = await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        return response;
      } else {
        throw SearxngApiException(
          'SearXNG instance error (HTTP ${response.statusCode}). Please verify instance settings.',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw SearxngApiException(
        'Request timed out (15s). Ensure your SearXNG docker container or instance is running at ${uri.scheme}://${uri.host}:${uri.port}.',
      );
    } on SocketException {
      throw SearxngApiException(
        'Could not connect to SearXNG at ${uri.scheme}://${uri.host}:${uri.port}. Ensure the Docker container is running ("docker run -d -p 8080:8080 searxng/searxng").',
      );
    } on http.ClientException catch (e) {
      throw SearxngApiException('Connection error: ${e.message}');
    }
  }
}
