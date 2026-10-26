class ImageResult {
  final String title;
  final String pageUrl;
  final String thumbnailUrl;
  final String imageUrl;
  final String source;
  final String? engine;

  const ImageResult({
    required this.title,
    required this.pageUrl,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.source,
    this.engine,
  });

  /// Constructs ImageResult from SearXNG image search result item.
  factory ImageResult.fromSearxngJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Untitled Image';
    final pageUrl = json['url'] as String? ?? json['page_url'] as String? ?? '';
    final engine = json['engine'] as String?;

    String imgUrl = json['img_src'] as String? ??
        json['image_url'] as String? ??
        json['url'] as String? ??
        '';

    String thumbUrl = json['thumbnail_src'] as String? ??
        json['thumbnail'] as String? ??
        json['img_src'] as String? ??
        imgUrl;

    if (imgUrl.isEmpty) {
      imgUrl = thumbUrl;
    }

    String sourceStr = '';
    if (json['source'] != null && (json['source'] as String).isNotEmpty) {
      sourceStr = json['source'] as String;
    } else if (pageUrl.isNotEmpty) {
      sourceStr = Uri.tryParse(pageUrl)?.host ?? '';
    }

    return ImageResult(
      title: title,
      pageUrl: pageUrl,
      thumbnailUrl: thumbUrl,
      imageUrl: imgUrl,
      source: sourceStr,
      engine: engine,
    );
  }

  /// Converts ImageResult to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': pageUrl,
      'img_src': imageUrl,
      'thumbnail_src': thumbnailUrl,
      'source': source,
      'engine': engine,
    };
  }

  /// Restores ImageResult from stored JSON map.
  factory ImageResult.fromJson(Map<String, dynamic> json) {
    return ImageResult(
      title: json['title'] as String? ?? '',
      pageUrl: json['url'] as String? ?? '',
      imageUrl: json['img_src'] as String? ?? '',
      thumbnailUrl: json['thumbnail_src'] as String? ?? '',
      source: json['source'] as String? ?? '',
      engine: json['engine'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageResult &&
          runtimeType == other.runtimeType &&
          imageUrl == other.imageUrl &&
          pageUrl == other.pageUrl;

  @override
  int get hashCode => imageUrl.hashCode ^ pageUrl.hashCode;
}
