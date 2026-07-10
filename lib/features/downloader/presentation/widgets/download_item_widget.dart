import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';
import 'package:omnidl/features/downloader/presentation/providers/download_providers.dart';

class DownloadItemWidget extends ConsumerWidget {
  final DownloadTask task;

  const DownloadItemWidget({
    super.key,
    required this.task,
  });

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isCompleted = task.status == DownloadStatus.completed;
    final isDownloading = task.status == DownloadStatus.downloading;
    final isPaused = task.status == DownloadStatus.paused;
    final isFailed = task.status == DownloadStatus.failed;

    IconData statusIcon;
    Color statusColor;
    String statusText = '';

    if (isCompleted) {
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
      statusText = 'Completed';
    } else if (isDownloading) {
      statusIcon = Icons.downloading;
      statusColor = colorScheme.primary;
      statusText = 'Downloading (${(task.progress * 100).toStringAsFixed(0)}%)';
    } else if (isPaused) {
      statusIcon = Icons.pause_circle_outline;
      statusColor = Colors.orange;
      statusText = 'Paused';
    } else if (isFailed) {
      statusIcon = Icons.error_outline;
      statusColor = colorScheme.error;
      statusText = 'Failed';
    } else {
      statusIcon = Icons.hourglass_empty;
      statusColor = Colors.grey;
      statusText = 'Queued';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (task.selectedQualityLabel != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.selectedQualityLabel!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        task.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDownloading)
                      IconButton(
                        icon: const Icon(Icons.pause, size: 20),
                        onPressed: () => ref.read(downloadEngineProvider).pause(task.id),
                        tooltip: 'Pause',
                      ),
                    if (isPaused)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 20),
                        onPressed: () => ref.read(downloadEngineProvider).resume(task.id),
                        tooltip: 'Resume',
                      ),
                    if (isFailed)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => ref.read(downloadEngineProvider).retry(task.id),
                        tooltip: 'Retry',
                      ),
                    IconButton(
                      icon: Icon(isCompleted ? Icons.delete_outline : Icons.close, size: 20),
                      onPressed: () => ref.read(downloadEngineProvider).cancel(task.id),
                      tooltip: isCompleted ? 'Delete' : 'Cancel',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  '${_formatSize(task.downloadedBytes)} / ${_formatSize(task.totalBytes)}',
                  style: TextStyle(
                    fontSize: 12,
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
                  value: task.totalBytes > 0 ? task.progress : null,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
            if (isFailed && task.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                task.errorMessage!,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
