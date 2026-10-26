import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../widgets/image_grid.dart';
import '../widgets/result_tile.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = context.read<SearchProvider>();
    _searchController = TextEditingController(text: provider.currentQuery);

    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<SearchProvider>().ensureTabLoaded(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchProvider>().search(
            query.trim(),
            initialTab: _tabController.index,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();

    if (_searchController.text != searchProvider.currentQuery &&
        !_searchController.selection.isValid) {
      _searchController.text = searchProvider.currentQuery;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearchSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'Bookmarks',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BookmarksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.public, size: 18),
              text: 'All',
            ),
            Tab(
              icon: Icon(Icons.newspaper, size: 18),
              text: 'News',
            ),
            Tab(
              icon: Icon(Icons.image, size: 18),
              text: 'Images',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Web ("All")
          _buildWebTab(context, searchProvider),

          // Tab 1: News
          _buildNewsTab(context, searchProvider),

          // Tab 2: Images
          _buildImagesTab(context, searchProvider),
        ],
      ),
    );
  }

  Widget _buildWebTab(BuildContext context, SearchProvider provider) {
    if (provider.isWebLoading) {
      return _buildLoadingState(context, 'Searching SearXNG for "${provider.currentQuery}"...');
    }
    if (provider.webError != null) {
      return _buildErrorState(context, provider.webError!, 0);
    }
    if (provider.webResults.isEmpty) {
      return _buildEmptyState(context, 'No results found for "${provider.currentQuery}".');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: provider.webResults.length,
      itemBuilder: (context, index) {
        return ResultTile(result: provider.webResults[index]);
      },
    );
  }

  Widget _buildNewsTab(BuildContext context, SearchProvider provider) {
    if (provider.isNewsLoading) {
      return _buildLoadingState(context, 'Searching news for "${provider.currentQuery}"...');
    }
    if (provider.newsError != null) {
      return _buildErrorState(context, provider.newsError!, 1);
    }
    if (provider.newsResults.isEmpty) {
      return _buildEmptyState(context, 'No news results found for "${provider.currentQuery}".');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: provider.newsResults.length,
      itemBuilder: (context, index) {
        return ResultTile(result: provider.newsResults[index]);
      },
    );
  }

  Widget _buildImagesTab(BuildContext context, SearchProvider provider) {
    if (provider.isImagesLoading) {
      return _buildLoadingState(context, 'Searching images for "${provider.currentQuery}"...');
    }
    if (provider.imagesError != null) {
      return _buildErrorState(context, provider.imagesError!, 2);
    }
    if (provider.imageResults.isEmpty) {
      return _buildEmptyState(context, 'No image results found for "${provider.currentQuery}".');
    }

    return ImageGrid(images: provider.imageResults);
  }

  Widget _buildLoadingState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage, int tabIndex) {
    final theme = Theme.of(context);
    final searchProvider = context.read<SearchProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Failed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    searchProvider.retryTabSearch(tabIndex);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Instance Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
