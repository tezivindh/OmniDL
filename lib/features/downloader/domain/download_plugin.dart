import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';

class DownloadMetadata {
  final String title;
  final int totalBytes;
  final String ext;

  DownloadMetadata({
    required this.title,
    required this.totalBytes,
    required this.ext,
  });
}

class DownloadStatusUpdate {
  final int downloadedBytes;
  final int totalBytes;
  final double progress;
  final DownloadStatus status;
  final String? errorMessage;

  DownloadStatusUpdate({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.errorMessage,
  });
}

abstract class DownloadPlugin {
  /// Return true if this plugin can handle the given URL.
  bool canHandle(String url);

  /// Fetch remote media information without starting the download.
  Future<DownloadMetadata> getMetadata(String url);

  /// Perform the download and return a stream of progress updates.
  /// The stream should emit updates on byte chunks and handle pause/cancel signals.
  Stream<DownloadStatusUpdate> download(
    DownloadTask task, {
    required String saveDirectory,
  });
}
