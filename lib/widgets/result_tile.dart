import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/search_result.dart';
import '../providers/search_provider.dart';

class ResultTile extends StatelessWidget {
  final SearchResult result;

  const ResultTile({super.key, required this.result});

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.tryParse(result.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: ${result.url}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();
    final isBookmarked = searchProvider.isBookmarked(result);

    final siteInfo = (result.publishedDate != null && result.publishedDate!.isNotEmpty)
        ? '${result.site} • ${result.publishedDate}'
        : result.site;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _launchUrl(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Site name, engine badge & Bookmark toggle button
              Row(
                children: [
                  Icon(
                    Icons.public,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            siteInfo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (result.engine != null && result.engine!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              result.engine!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: isBookmarked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark result',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    onPressed: () {
                      searchProvider.toggleBookmark(result);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title (clickable, primary color)
              SelectableText.rich(
                TextSpan(
                  text: result.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _launchUrl(context),
              ),
              if (result.description.isNotEmpty) ...[
                const SizedBox(height: 6),

                // Short description
                Text(
                  result.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
