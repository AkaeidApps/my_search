import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import 'bookmarks_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showHistory = _focusNode.hasFocus && _controller.text.isEmpty;
    });
  }

  void _onTextChange() {
    setState(() {
      _showHistory = _focusNode.hasFocus && _controller.text.isEmpty;
    });
  }

  void _performSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    _focusNode.unfocus();
    final provider = context.read<SearchProvider>();
    provider.search(clean, initialTab: 0);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ResultsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();
    final history = searchProvider.searchHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MySearch'),
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // App Logo/Icon & Centered Title
                  Icon(
                    Icons.travel_explore,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MySearch',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Privacy-friendly search client powered by SearXNG',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Search input row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: _performSearch,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search web, news, or images...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _controller.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _performSearch(_controller.text),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),

                  // Search History Suggestions under search box when focused and empty
                  if (_showHistory && history.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Searches',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    searchProvider.clearHistory();
                                  },
                                  icon: const Icon(Icons.delete_sweep, size: 16),
                                  label: const Text('Clear history'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.history, size: 18),
                                title: Text(item),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    searchProvider.removeFromHistory(item);
                                  },
                                ),
                                onTap: () {
                                  _controller.text = item;
                                  _performSearch(item);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
