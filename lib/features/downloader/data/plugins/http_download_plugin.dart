import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_plugin.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';

class HttpDownloadPlugin implements DownloadPlugin {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  @override
  bool canHandle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Future<DownloadMetadata> getMetadata(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLengthStr = response.headers.value('content-length');
      final totalBytes = contentLengthStr != null ? int.tryParse(contentLengthStr) ?? -1 : -1;

      String filename = '';
      final contentDisposition = response.headers.value('content-disposition');
      if (contentDisposition != null) {
        final regExp = RegExp(r'filename="?([^";\n]+)"?');
        final match = regExp.firstMatch(contentDisposition);
        if (match != null && match.groupCount >= 1) {
          filename = match.group(1)!;
        }
      }

      if (filename.isEmpty) {
        filename = url.split('/').last.split('?').first;
      }
      if (filename.isEmpty) {
        filename = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }

      final ext = filename.contains('.') ? filename.split('.').last : 'bin';
      return DownloadMetadata(
        title: filename,
        totalBytes: totalBytes,
        ext: ext,
      );
    } catch (_) {
      // Fallback to a quick GET with stream if HEAD fails (some servers block HEAD)
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final contentLengthStr = response.headers.value('content-length');
      final totalBytes = contentLengthStr != null ? int.tryParse(contentLengthStr) ?? -1 : -1;

      String filename = url.split('/').last.split('?').first;
      if (filename.isEmpty) {
        filename = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }

      final ext = filename.contains('.') ? filename.split('.').last : 'bin';
      return DownloadMetadata(
        title: filename,
        totalBytes: totalBytes,
        ext: ext,
      );
    }
  }

  @override
  Stream<DownloadStatusUpdate> download(
    DownloadTask task, {
    required String saveDirectory,
  }) {
    final controller = StreamController<DownloadStatusUpdate>();
    final cancelToken = CancelToken();

    controller.onCancel = () {
      cancelToken.cancel('Download stream subscription cancelled');
    };

    _executeDownload(task, controller, cancelToken);

    return controller.stream;
  }

  Future<void> _executeDownload(
    DownloadTask task,
    StreamController<DownloadStatusUpdate> controller,
    CancelToken cancelToken,
  ) async {
    IOSink? sink;
    try {
      final file = File(task.savePath);
      int downloadedBytes = 0;
      if (await file.exists()) {
        downloadedBytes = await file.length();
      }

      // Verify directory structure exists
      final directory = Directory(file.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Check if we are already done
      if (task.totalBytes > 0 && downloadedBytes >= task.totalBytes) {
        controller.add(DownloadStatusUpdate(
          downloadedBytes: downloadedBytes,
          totalBytes: task.totalBytes,
          progress: 1.0,
          status: DownloadStatus.completed,
        ));
        await controller.close();
        return;
      }

      // Make connection request
      final response = await _dio.get<ResponseBody>(
        task.url,
        options: Options(
          responseType: ResponseType.stream,
          headers: downloadedBytes > 0 ? {'Range': 'bytes=$downloadedBytes-'} : null,
        ),
        cancelToken: cancelToken,
      );

      final contentLengthStr = response.headers.value('content-length');
      final responseLength = contentLengthStr != null ? int.tryParse(contentLengthStr) ?? -1 : -1;
      
      int totalBytes = task.totalBytes;
      if (responseLength != -1) {
        totalBytes = responseLength + downloadedBytes;
      }

      final fileMode = downloadedBytes > 0 ? FileMode.append : FileMode.write;
      sink = file.openWrite(mode: fileMode);

      int currentDownloaded = downloadedBytes;

      await for (final chunk in response.data!.stream) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: task.url),
            type: DioExceptionType.cancel,
            message: 'Download cancelled',
          );
        }
        sink.add(chunk);
        currentDownloaded += chunk.length;

        final progress = totalBytes > 0 ? currentDownloaded / totalBytes : 0.0;
        controller.add(DownloadStatusUpdate(
          downloadedBytes: currentDownloaded,
          totalBytes: totalBytes,
          progress: progress,
          status: DownloadStatus.downloading,
        ));
      }

      await sink.flush();
      await sink.close();
      sink = null;

      controller.add(DownloadStatusUpdate(
        downloadedBytes: currentDownloaded,
        totalBytes: totalBytes,
        progress: 1.0,
        status: DownloadStatus.completed,
      ));
      await controller.close();

    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }

      if (e is DioException && e.type == DioExceptionType.cancel) {
        controller.add(DownloadStatusUpdate(
          downloadedBytes: task.downloadedBytes,
          totalBytes: task.totalBytes,
          progress: task.progress,
          status: DownloadStatus.paused,
        ));
      } else {
        controller.add(DownloadStatusUpdate(
          downloadedBytes: task.downloadedBytes,
          totalBytes: task.totalBytes,
          progress: task.progress,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        ));
      }
      await controller.close();
    }
  }
}
