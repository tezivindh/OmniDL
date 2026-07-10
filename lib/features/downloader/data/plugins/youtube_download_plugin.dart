import 'dart:async';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_plugin.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';

class YoutubeDownloadPlugin implements DownloadPlugin {
  @override
  bool canHandle(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com/') ||
        lowerUrl.contains('youtu.be/') ||
        lowerUrl.contains('youtube-nocookie.com/');
  }

  @override
  Future<DownloadMetadata> getMetadata(String url) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(url);
      final streamInfo = manifest.muxed.withHighestBitrate();
      
      final cleanTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final ext = streamInfo.container.name;
      final size = streamInfo.size.totalBytes;

      return DownloadMetadata(
        title: '$cleanTitle.$ext',
        totalBytes: size,
        ext: ext,
      );
    } finally {
      yt.close();
    }
  }

  @override
  Future<List<DownloadQualityOption>> getQualityOptions(String url) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(url);
      final List<DownloadQualityOption> options = [];

      // Add Muxed Video streams (video + audio) sorted descending by resolution/bitrate
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      for (final stream in muxedStreams) {
        options.add(
          DownloadQualityOption(
            id: 'muxed_${stream.qualityLabel}',
            label: 'Video - ${stream.qualityLabel} (${stream.container.name.toUpperCase()})',
            sizeInBytes: stream.size.totalBytes,
          ),
        );
      }

      // Add highest audio-only stream if available
      if (manifest.audioOnly.isNotEmpty) {
        final bestAudio = manifest.audioOnly.withHighestBitrate();
        options.add(
          DownloadQualityOption(
            id: 'audio_best',
            label: 'Audio Only (${bestAudio.container.name.toUpperCase()})',
            sizeInBytes: bestAudio.size.totalBytes,
          ),
        );
      }

      if (options.isEmpty) {
        options.add(
          DownloadQualityOption(
            id: 'default',
            label: 'Default Quality',
            sizeInBytes: -1,
          ),
        );
      }

      return options;
    } catch (_) {
      return [
        DownloadQualityOption(
          id: 'default',
          label: 'Default Quality',
          sizeInBytes: -1,
        ),
      ];
    } finally {
      yt.close();
    }
  }

  @override
  Stream<DownloadStatusUpdate> download(
    DownloadTask task, {
    required String saveDirectory,
  }) {
    final controller = StreamController<DownloadStatusUpdate>();
    final yt = YoutubeExplode();

    _executeYoutubeDownload(task, controller, yt);

    return controller.stream;
  }

  Future<void> _executeYoutubeDownload(
    DownloadTask task,
    StreamController<DownloadStatusUpdate> controller,
    YoutubeExplode yt,
  ) async {
    IOSink? sink;
    StreamSubscription? networkSubscription;
    bool isCancelled = false;

    controller.onCancel = () async {
      isCancelled = true;
      await networkSubscription?.cancel();
      try {
        await sink?.close();
      } catch (_) {}
      yt.close();
    };

    try {
      final file = File(task.savePath);
      final directory = Directory(file.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final manifest = await yt.videos.streamsClient.getManifest(task.url);
      dynamic streamInfo;

      if (task.selectedQualityId != null) {
        if (task.selectedQualityId == 'audio_best') {
          streamInfo = manifest.audioOnly.withHighestBitrate();
        } else if (task.selectedQualityId!.startsWith('muxed_')) {
          final qualityLabel = task.selectedQualityId!.replaceFirst('muxed_', '');
          for (final s in manifest.muxed) {
            if (s.qualityLabel == qualityLabel) {
              streamInfo = s;
              break;
            }
          }
        }
      }

      // Fallback if quality option was not resolved/found
      streamInfo ??= manifest.muxed.withHighestBitrate();

      final totalBytes = streamInfo.size.totalBytes;

      sink = file.openWrite(mode: FileMode.write);
      final networkStream = yt.videos.streamsClient.get(streamInfo);

      int currentDownloaded = 0;

      networkSubscription = networkStream.listen(
        (chunk) {
          if (isCancelled) return;
          sink!.add(chunk);
          currentDownloaded += chunk.length;

          final progress = totalBytes > 0 ? currentDownloaded / totalBytes : 0.0;
          controller.add(DownloadStatusUpdate(
            downloadedBytes: currentDownloaded,
            totalBytes: totalBytes,
            progress: progress,
            status: DownloadStatus.downloading,
          ));
        },
        onDone: () async {
          if (isCancelled) return;
          try {
            await sink!.flush();
            await sink!.close();
          } catch (_) {}
          sink = null;
          yt.close();
          
          controller.add(DownloadStatusUpdate(
            downloadedBytes: currentDownloaded,
            totalBytes: totalBytes,
            progress: 1.0,
            status: DownloadStatus.completed,
          ));
          await controller.close();
        },
        onError: (e) async {
          try {
            await sink?.close();
          } catch (_) {}
          yt.close();
          if (!isCancelled) {
            controller.add(DownloadStatusUpdate(
              downloadedBytes: currentDownloaded,
              totalBytes: totalBytes,
              progress: totalBytes > 0 ? currentDownloaded / totalBytes : 0.0,
              status: DownloadStatus.failed,
              errorMessage: e.toString(),
            ));
            await controller.close();
          }
        },
        cancelOnError: true,
      );

    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      yt.close();
      if (!isCancelled) {
        controller.add(DownloadStatusUpdate(
          downloadedBytes: task.downloadedBytes,
          totalBytes: task.totalBytes,
          progress: task.progress,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        ));
        await controller.close();
      }
    }
  }
}
