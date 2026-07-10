import 'package:omnidl/features/downloader/domain/download_task.dart';

abstract class DownloaderRepository {
  /// Fetch all stored download tasks from database.
  Future<List<DownloadTask>> getAllTasks();

  /// Watch stored download tasks in real-time.
  Stream<List<DownloadTask>> watchAllTasks();

  /// Get a single task by ID.
  Future<DownloadTask?> getTask(int id);

  /// Save or update task state in database, returns the task ID.
  Future<int> insertOrUpdateTask(DownloadTask task);

  /// Delete a task by ID.
  Future<void> deleteTask(int id);
}
