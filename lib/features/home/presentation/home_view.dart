import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleDownload() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid URL'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    // For now, show a info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Start Download'),
          ],
        ),
        content: Text('Downloading from URL:\n\n$url\n\nThe download engine is being set up in the next feature phase!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.indigoAccent, Colors.purpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'OmniDL',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                            fontFamily: theme.textTheme.headlineLarge?.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Universal Media Downloader & Player',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.person, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Paste Link Area
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paste media link',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Insert any supported video or audio URL below',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                hintText: 'https://example.com/media/file.mp4',
                                prefixIcon: Icon(Icons.link),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onSubmitted: (_) => _handleDownload(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              minimumSize: const Size(60, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _handleDownload,
                            child: const Icon(Icons.download),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Supported Platforms Badges
              Text(
                'Supported Platforms & Formats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(context, Icons.video_collection, 'MP4 / MKV / WEBM'),
                  _buildBadge(context, Icons.audiotrack, 'MP3 / AAC / FLAC'),
                  _buildBadge(context, Icons.subtitles, 'SRT / VTT subtitles'),
                  _buildBadge(context, Icons.link, 'Direct File Links'),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity Dashboard
              Text(
                'Recent Downloads',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              _buildMockDownloadItem(
                context,
                title: 'Introduction to Flutter Clean Architecture.mp4',
                source: 'youtube.com',
                size: '24.5 MB',
                progress: 1.0,
                isCompleted: true,
              ),
              const SizedBox(height: 10),
              _buildMockDownloadItem(
                context,
                title: 'Lo-Fi Chill Beats Mix for Coding.mp3',
                source: 'soundcloud.com',
                size: '48.1 MB',
                progress: 0.72,
                isCompleted: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockDownloadItem(
    BuildContext context, {
    required String title,
    required String source,
    required String size,
    required double progress,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? colorScheme.primaryContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.downloading,
                color: isCompleted ? colorScheme.primary : colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        source,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        size,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
