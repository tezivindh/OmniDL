import 'package:isar/isar.dart';
import 'package:omnidl/core/storage/isar_service.dart';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';
import 'package:omnidl/features/downloader/domain/downloader_repository.dart';

class DownloaderRepositoryImpl implements DownloaderRepository {
  Isar get isar => IsarService.instance.isar;

  @override
  Future<List<DownloadTask>> getAllTasks() async {
    final models = await isar.downloadTaskModels.where().sortByCreatedAtDesc().findAll();
    return models.map((m) => DownloadTask.fromModel(m)).toList();
  }

  @override
  Stream<List<DownloadTask>> watchAllTasks() {
    return isar.downloadTaskModels
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((models) => models.map((m) => DownloadTask.fromModel(m)).toList());
  }

  @override
  Future<DownloadTask?> getTask(int id) async {
    final model = await isar.downloadTaskModels.get(id);
    if (model == null) return null;
    return DownloadTask.fromModel(model);
  }

  @override
  Future<int> insertOrUpdateTask(DownloadTask task) async {
    final model = task.toModel();
    late int id;
    await isar.writeTxn(() async {
      id = await isar.downloadTaskModels.put(model);
    });
    return id;
  }

  @override
  Future<void> deleteTask(int id) async {
    await isar.writeTxn(() async {
      await isar.downloadTaskModels.delete(id);
    });
  }
}
