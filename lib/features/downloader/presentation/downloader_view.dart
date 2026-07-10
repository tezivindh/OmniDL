import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnidl/features/downloader/presentation/providers/download_providers.dart';
import 'package:omnidl/features/downloader/presentation/widgets/download_item_widget.dart';

class DownloaderView extends ConsumerWidget {
  const DownloaderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadsAsync = ref.watch(downloadListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: downloadsAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline_outlined,
                    size: 72,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No downloads yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Home and paste a URL to start downloading.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return DownloadItemWidget(task: task);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load downloads: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
    );
  }
}
