class SearchResult {
  final String title;
  final String url;
  final String description;
  final String site;
  final String? engine;
  final String? publishedDate;

  const SearchResult({
    required this.title,
    required this.url,
    required this.description,
    required this.site,
    this.engine,
    this.publishedDate,
  });

  /// Strips HTML tags and decodes common HTML entities.
  static String stripHtml(String text) {
    final htmlTagPattern = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    var cleanText = text.replaceAll(htmlTagPattern, '');

    cleanText = cleanText
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');

    return cleanText.trim();
  }

  /// Trims content to maxLength (default 250) after stripping HTML.
  static String trimContent(String text, {int maxLength = 250}) {
    final clean = stripHtml(text);
    if (clean.length <= maxLength) {
      return clean;
    }
    return '${clean.substring(0, maxLength).trim()}...';
  }

  /// Formats date or relative time string.
  static String? formatRelativeTime(String? dateStr, {DateTime? nowForTesting}) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      // If it's already a relative date string like "2 hours ago" or "Yesterday"
      return trimmed;
    }

    final nowUtc = (nowForTesting ?? DateTime.now()).toUtc();
    final parsedUtc = parsed.toUtc();
    final difference = nowUtc.difference(parsedUtc);

    if (difference.isNegative) return 'just now';

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }

  /// Constructs SearchResult from SearXNG JSON result item.
  factory SearchResult.fromSearxngJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String? ?? 'No title';
    final rawUrl = json['url'] as String? ?? '';
    final rawContent = json['content'] as String? ?? json['snippet'] as String? ?? '';
    final engine = json['engine'] as String?;

    String hostname = '';
    if (rawUrl.isNotEmpty) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null && uri.host.isNotEmpty) {
        hostname = uri.host;
      }
    }
    if (hostname.isEmpty) {
      hostname = 'unknown';
    }

    final rawDate = json['publishedDate'] as String? ??
        json['published_date'] as String? ??
        json['published_date_relative'] as String?;

    return SearchResult(
      title: stripHtml(rawTitle),
      url: rawUrl,
      description: trimContent(rawContent, maxLength: 250),
      site: hostname,
      engine: engine,
      publishedDate: formatRelativeTime(rawDate),
    );
  }

  /// Converts SearchResult to JSON for local bookmark persistence.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'site': site,
      'engine': engine,
      'publishedDate': publishedDate,
    };
  }

  /// Restores SearchResult from stored JSON map.
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      site: json['site'] as String? ?? '',
      engine: json['engine'] as String?,
      publishedDate: json['publishedDate'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
