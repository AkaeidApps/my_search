import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../services/searxng_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SearchProvider>();
    _controller = TextEditingController(text: provider.instanceUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    setState(() {
      _validationError = null;
    });

    final url = _controller.text;
    final provider = context.read<SearchProvider>();
    final error = await provider.setInstanceUrl(url);

    if (error != null) {
      setState(() {
        _validationError = error;
      });
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SearXNG Instance URL saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetDefault() async {
    final provider = context.read<SearchProvider>();
    await provider.resetInstanceUrl();
    _controller.text = SearxngApiService.defaultInstanceUrl;
    setState(() {
      _validationError = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default (http://localhost:8080).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SearXNG Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dns, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              'SearXNG Instance URL',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Configure the base URL of your local or public SearXNG instance. Defaults to local docker (http://localhost:8080).',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          onChanged: (_) {
                            if (_validationError != null) {
                              setState(() {
                                _validationError = null;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Instance Base URL',
                            hintText: 'http://localhost:8080',
                            errorText: _validationError,
                            errorMaxLines: 2,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.link),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _saveUrl,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Settings'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _resetDefault,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset to Default'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Docker setup help card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.terminal, color: theme.colorScheme.secondary),
                            const SizedBox(width: 10),
                            Text(
                              'Running SearXNG via Docker',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'To run SearXNG locally using Docker, execute the following command in your terminal:',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            'docker run -d -p 8080:8080 searxng/searxng',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
