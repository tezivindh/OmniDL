import 'package:omnidl/features/downloader/data/models/download_task_model.dart';

class DownloadTask {
  final int id;
  final String url;
  final String title;
  final String savePath;
  final DownloadStatus status;
  final double progress;
  final int totalBytes;
  final int downloadedBytes;
  final String? errorMessage;
  final String? selectedQualityId;
  final String? selectedQualityLabel;
  final DateTime createdAt;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.savePath,
    required this.status,
    required this.progress,
    required this.totalBytes,
    required this.downloadedBytes,
    this.errorMessage,
    this.selectedQualityId,
    this.selectedQualityLabel,
    required this.createdAt,
  });

  DownloadTask copyWith({
    int? id,
    String? url,
    String? title,
    String? savePath,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    String? errorMessage,
    String? selectedQualityId,
    String? selectedQualityLabel,
    DateTime? createdAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      savePath: savePath ?? this.savePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedQualityId: selectedQualityId ?? this.selectedQualityId,
      selectedQualityLabel: selectedQualityLabel ?? this.selectedQualityLabel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to and from Isar model
  DownloadTaskModel toModel() {
    return DownloadTaskModel()
      ..id = id
      ..url = url
      ..title = title
      ..savePath = savePath
      ..status = status
      ..progress = progress
      ..totalBytes = totalBytes
      ..downloadedBytes = downloadedBytes
      ..errorMessage = errorMessage
      ..selectedQualityId = selectedQualityId
      ..selectedQualityLabel = selectedQualityLabel
      ..createdAt = createdAt;
  }

  factory DownloadTask.fromModel(DownloadTaskModel model) {
    return DownloadTask(
      id: model.id,
      url: model.url,
      title: model.title,
      savePath: model.savePath,
      status: model.status,
      progress: model.progress,
      totalBytes: model.totalBytes,
      downloadedBytes: model.downloadedBytes,
      errorMessage: model.errorMessage,
      selectedQualityId: model.selectedQualityId,
      selectedQualityLabel: model.selectedQualityLabel,
      createdAt: model.createdAt,
    );
  }
}
