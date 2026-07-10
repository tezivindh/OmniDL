import 'package:isar/isar.dart';

part 'download_task_model.g.dart';

@collection
class DownloadTaskModel {
  Id id = Isar.autoIncrement;

  late String url;
  late String title;
  late String savePath;

  @enumerated
  late DownloadStatus status;

  late double progress;
  late int totalBytes;
  late int downloadedBytes;

  String? errorMessage;
  
  late DateTime createdAt;
}

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}
