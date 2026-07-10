import 'dart:async';
import 'dart:io';
import 'package:omnidl/features/downloader/application/downloader_plugin_registry.dart';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';
import 'package:omnidl/features/downloader/domain/downloader_repository.dart';
import 'package:omnidl/features/downloader/domain/download_plugin.dart';

class DownloadEngine {
  final DownloaderRepository repository;
  final int maxConcurrency;

  DownloadEngine({
    required this.repository,
    this.maxConcurrency = 3,
  });

  final Map<int, StreamSubscription<DownloadStatusUpdate>> _activeSubscriptions = {};

  Future<void> enqueue(String url, String saveDirectory) async {
    final plugin = DownloaderPluginRegistry.instance.findPlugin(url);
    final metadata = await plugin.getMetadata(url);
    
    // Ensure filename matches filesystem safety rules
    final safeTitle = metadata.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final savePath = '$saveDirectory/$safeTitle';

    final task = DownloadTask(
      id: 0, // Isar auto increment
      url: url,
      title: metadata.title,
      savePath: savePath,
      status: DownloadStatus.queued,
      progress: 0.0,
      totalBytes: metadata.totalBytes,
      downloadedBytes: 0,
      createdAt: DateTime.now(),
    );

    await repository.insertOrUpdateTask(task);
    _processQueue();
  }

  Future<void> pause(int id) async {
    final subscription = _activeSubscriptions[id];
    if (subscription != null) {
      await subscription.cancel();
      _activeSubscriptions.remove(id);
    }
    
    final task = await repository.getTask(id);
    if (task != null) {
      final updated = task.copyWith(
        status: DownloadStatus.paused,
      );
      await repository.insertOrUpdateTask(updated);
    }
    _processQueue();
  }

  Future<void> resume(int id) async {
    final task = await repository.getTask(id);
    if (task != null) {
      final updated = task.copyWith(
        status: DownloadStatus.queued,
      );
      await repository.insertOrUpdateTask(updated);
    }
    _processQueue();
  }

  Future<void> cancel(int id) async {
    final subscription = _activeSubscriptions[id];
    if (subscription != null) {
      await subscription.cancel();
      _activeSubscriptions.remove(id);
    }

    final task = await repository.getTask(id);
    if (task != null) {
      final file = File(task.savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await repository.deleteTask(id);
    }
    _processQueue();
  }

  Future<void> retry(int id) async {
    await resume(id);
  }

  Future<void> _processQueue() async {
    final allTasks = await repository.getAllTasks();
    
    final downloadingCount = allTasks.where((t) => t.status == DownloadStatus.downloading).length;
    
    if (downloadingCount >= maxConcurrency) {
      return;
    }

    final queuedTasks = allTasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (queuedTasks.isEmpty) {
      return;
    }

    // Process oldest queued task first
    queuedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final nextTask = queuedTasks.first;

    _startDownload(nextTask);
  }

  void _startDownload(DownloadTask task) {
    if (_activeSubscriptions.containsKey(task.id)) return;

    final plugin = DownloaderPluginRegistry.instance.findPlugin(task.url);

    // Update status to downloading in database
    final startedTask = task.copyWith(status: DownloadStatus.downloading);
    repository.insertOrUpdateTask(startedTask);

    final stream = plugin.download(
      startedTask,
      saveDirectory: File(task.savePath).parent.path,
    );

    final subscription = stream.listen(
      (update) async {
        final currentTask = await repository.getTask(task.id);
        if (currentTask == null || currentTask.status != DownloadStatus.downloading) {
          return;
        }

        final updated = currentTask.copyWith(
          downloadedBytes: update.downloadedBytes,
          totalBytes: update.totalBytes,
          progress: update.progress,
          status: update.status,
          errorMessage: update.errorMessage,
        );
        await repository.insertOrUpdateTask(updated);

        if (update.status == DownloadStatus.completed || update.status == DownloadStatus.failed) {
          _activeSubscriptions.remove(task.id);
          _processQueue();
        }
      },
      onError: (e) async {
        _activeSubscriptions.remove(task.id);
        final currentTask = await repository.getTask(task.id);
        if (currentTask != null) {
          final updated = currentTask.copyWith(
            status: DownloadStatus.failed,
            errorMessage: e.toString(),
          );
          await repository.insertOrUpdateTask(updated);
        }
        _processQueue();
      },
      onDone: () {
        _activeSubscriptions.remove(task.id);
        _processQueue();
      },
    );

    _activeSubscriptions[task.id] = subscription;
  }
}
