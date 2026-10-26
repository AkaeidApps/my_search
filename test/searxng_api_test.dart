import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mysearch/models/image_result.dart';
import 'package:mysearch/models/search_result.dart';
import 'package:mysearch/services/searxng_api.dart';

void main() {
  group('HTML Stripping & Content Trimming Tests', () {
    test('strips HTML tags and decodes entities', () {
      const raw = 'SearXNG <strong>Privacy</strong> &amp; <i>Search</i>.';
      final cleaned = SearchResult.stripHtml(raw);
      expect(cleaned, equals('SearXNG Privacy & Search.'));
    });

    test('trimContent trims to 250 chars with ellipsis', () {
      final longText = 'A' * 300;
      final trimmed = SearchResult.trimContent(longText, maxLength: 250);
      expect(trimmed.length, equals(253));
      expect(trimmed.endsWith('...'), isTrue);
    });
  });

  group('Relative Time Formatting Tests', () {
    final fixedNow = DateTime.utc(2025, 2, 14, 12, 0, 0);

    test('formats minutes and hours ago', () {
      const pastMinutes = '2025-02-14T11:45:00Z';
      expect(
        SearchResult.formatRelativeTime(pastMinutes, nowForTesting: fixedNow),
        equals('15 minutes ago'),
      );

      const pastHours = '2025-02-14T09:00:00Z';
      expect(
        SearchResult.formatRelativeTime(pastHours, nowForTesting: fixedNow),
        equals('3 hours ago'),
      );
    });

    test('returns original string if already relative or non-ISO', () {
      expect(SearchResult.formatRelativeTime('Yesterday'), equals('Yesterday'));
      expect(SearchResult.formatRelativeTime('2 hours ago'), equals('2 hours ago'));
    });
  });

  group('Instance URL Validation & Normalization Tests', () {
    test('normalizes URLs removing trailing slashes', () {
      expect(
        SearxngApiService.normalizeInstanceUrl('http://localhost:8080/'),
        equals('http://localhost:8080'),
      );
      expect(
        SearxngApiService.normalizeInstanceUrl('  https://searx.example.org/// '),
        equals('https://searx.example.org'),
      );
    });

    test('validates valid http/https URLs', () {
      expect(SearxngApiService.validateInstanceUrl('http://localhost:8080'), isNull);
      expect(SearxngApiService.validateInstanceUrl('https://searx.be'), isNull);
    });

    test('rejects invalid schemes or malformed URLs', () {
      expect(
        SearxngApiService.validateInstanceUrl('ftp://localhost:8080'),
        contains('must start with http:// or https://'),
      );
      expect(
        SearxngApiService.validateInstanceUrl('localhost:8080'),
        contains('must start with http:// or https://'),
      );
    });
  });

  group('JSON Parsing Tests', () {
    test('SearchResult.fromSearxngJson parses result with engine', () {
      final jsonMap = {
        'title': '<strong>SearXNG</strong> - Metasearch Engine',
        'url': 'https://searxng.org',
        'content': 'SearXNG is a free internet metasearch engine.',
        'engine': 'google',
      };

      final result = SearchResult.fromSearxngJson(jsonMap);

      expect(result.title, equals('SearXNG - Metasearch Engine'));
      expect(result.url, equals('https://searxng.org'));
      expect(result.site, equals('searxng.org'));
      expect(result.engine, equals('google'));
    });

    test('ImageResult.fromSearxngJson parses image result fields', () {
      final jsonMap = {
        'title': 'SearXNG Logo',
        'url': 'https://searxng.org/logo',
        'img_src': 'https://searxng.org/images/logo.png',
        'thumbnail_src': 'https://searxng.org/images/logo_thumb.png',
        'engine': 'bing',
      };

      final imageResult = ImageResult.fromSearxngJson(jsonMap);

      expect(imageResult.title, equals('SearXNG Logo'));
      expect(imageResult.pageUrl, equals('https://searxng.org/logo'));
      expect(imageResult.imageUrl, equals('https://searxng.org/images/logo.png'));
      expect(imageResult.thumbnailUrl, equals('https://searxng.org/images/logo_thumb.png'));
      expect(imageResult.engine, equals('bing'));
    });
  });

  group('SearxngApiService HTTP Tests', () {
    test('search sends request to SearXNG API endpoint and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals('http://localhost:8080/search?q=flutter&categories=general&format=json'),
        );

        return http.Response(
          jsonEncode({
            'results': [
              {
                'title': 'Flutter Framework',
                'url': 'https://flutter.dev',
                'content': 'Flutter is an open-source UI toolkit.',
                'engine': 'duckduckgo',
              }
            ]
          }),
          200,
        );
      });

      final apiService = SearxngApiService(client: mockClient);
      final results = await apiService.search(
        query: 'flutter',
        instanceUrl: 'http://localhost:8080',
        category: 'general',
      );

      expect(results.length, equals(1));
      expect(results.first.title, equals('Flutter Framework'));
      expect(results.first.engine, equals('duckduckgo'));
    });

    test('searchImages sends request for categories=images and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals('http://localhost:8080/search?q=linux&categories=images&format=json'),
        );

        return http.Response(
          jsonEncode({
            'results': [
              {
                'title': 'Linux Tux',
                'url': 'https://kernel.org/tux',
                'img_src': 'https://kernel.org/tux.png',
                'thumbnail_src': 'https://kernel.org/tux_thumb.png',
                'engine': 'google',
              }
            ]
          }),
          200,
        );
      });

      final apiService = SearxngApiService(client: mockClient);
      final images = await apiService.searchImages(
        query: 'linux',
        instanceUrl: 'http://localhost:8080',
      );

      expect(images.length, equals(1));
      expect(images.first.title, equals('Linux Tux'));
      expect(images.first.imageUrl, equals('https://kernel.org/tux.png'));
    });
  });
}
