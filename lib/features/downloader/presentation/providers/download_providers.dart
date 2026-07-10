import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnidl/features/downloader/application/download_engine.dart';
import 'package:omnidl/features/downloader/data/repositories/downloader_repository_impl.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';
import 'package:omnidl/features/downloader/domain/downloader_repository.dart';

final downloaderRepositoryProvider = Provider<DownloaderRepository>((ref) {
  return DownloaderRepositoryImpl();
});

final downloadEngineProvider = Provider<DownloadEngine>((ref) {
  final repository = ref.watch(downloaderRepositoryProvider);
  return DownloadEngine(repository: repository);
});

final downloadListProvider = StreamProvider<List<DownloadTask>>((ref) {
  final repository = ref.watch(downloaderRepositoryProvider);
  return repository.watchAllTasks();
});
