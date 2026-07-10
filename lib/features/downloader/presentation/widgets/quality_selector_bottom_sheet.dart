import 'package:flutter/material.dart';
import 'package:omnidl/features/downloader/application/downloader_plugin_registry.dart';
import 'package:omnidl/features/downloader/domain/download_plugin.dart';

class QualitySelectorBottomSheet extends StatefulWidget {
  final String url;

  const QualitySelectorBottomSheet({
    super.key,
    required this.url,
  });

  static Future<DownloadQualityOption?> show(BuildContext context, String url) {
    return showModalBottomSheet<DownloadQualityOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => QualitySelectorBottomSheet(url: url),
    );
  }

  @override
  State<QualitySelectorBottomSheet> createState() => _QualitySelectorBottomSheetState();
}

class _QualitySelectorBottomSheetState extends State<QualitySelectorBottomSheet> {
  late Future<List<DownloadQualityOption>> _optionsFuture;

  @override
  void initState() {
    super.initState();
    final plugin = DownloaderPluginRegistry.instance.findPlugin(widget.url);
    _optionsFuture = plugin.getQualityOptions(widget.url);
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double wBytes = bytes.toDouble();
    while (wBytes >= 1024 && i < suffixes.length - 1) {
      wBytes /= 1024;
      i++;
    }
    return '${wBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Download Quality',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<DownloadQualityOption>>(
            future: _optionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load qualities',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            DownloadQualityOption(
                              id: 'default',
                              label: 'Default Quality',
                              sizeInBytes: -1,
                            ),
                          );
                        },
                        child: const Text('Download Anyway'),
                      ),
                    ],
                  ),
                );
              }

              final options = snapshot.data ?? [];
              if (options.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No stream options available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isAudio = option.id.startsWith('audio_');
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isAudio
                          ? Colors.orange.withOpacity(0.15)
                          : colorScheme.primary.withOpacity(0.15),
                      child: Icon(
                        isAudio ? Icons.audiotrack : Icons.play_circle_filled,
                        color: isAudio ? Colors.orange : colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      option.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      _formatSize(option.sizeInBytes),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
