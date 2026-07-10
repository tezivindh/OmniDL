import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';
import 'package:omnidl/features/downloader/domain/download_plugin.dart';
import 'package:omnidl/features/downloader/domain/download_task.dart';

class YoutubeDownloadPlugin implements DownloadPlugin {
  // Helper to find the yt-dlp executable
  Future<String> _getYtdlpExecutable() async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final localYtdlp = '$homeDir/.local/bin/yt-dlp';
    if (await File(localYtdlp).exists()) {
      return localYtdlp;
    }
    return 'yt-dlp';
  }

  @override
  bool canHandle(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com/') ||
        lowerUrl.contains('youtu.be/') ||
        lowerUrl.contains('youtube-nocookie.com/');
  }

  @override
  Future<DownloadMetadata> getMetadata(String url) async {
    try {
      final ytdlp = await _getYtdlpExecutable();
      final result = await Process.run(ytdlp, [
        '--js-runtimes', 'node',
        '--dump-json',
        '--skip-download',
        url,
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to fetch metadata: ${result.stderr}');
      }

      final json = jsonDecode(result.stdout as String);
      final title = json['title'] as String? ?? 'video';
      final cleanTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      final ext = json['ext'] as String? ?? 'mp4';
      
      int totalBytes = 0;
      if (json['filesize'] != null) {
        totalBytes = json['filesize'] as int;
      } else if (json['filesize_approx'] != null) {
        totalBytes = json['filesize_approx'] as int;
      }

      return DownloadMetadata(
        title: '$cleanTitle.$ext',
        totalBytes: totalBytes,
        ext: ext,
      );
    } catch (e) {
      print('OmniDL [YoutubeDownloadPlugin] getMetadata error: $e');
      rethrow;
    }
  }

  @override
  Future<List<DownloadQualityOption>> getQualityOptions(String url) async {
    try {
      final ytdlp = await _getYtdlpExecutable();
      final result = await Process.run(ytdlp, [
        '--js-runtimes', 'node',
        '--dump-json',
        '--skip-download',
        url,
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to fetch metadata from yt-dlp: ${result.stderr}');
      }

      final json = jsonDecode(result.stdout as String);
      final formats = json['formats'] as List<dynamic>;

      // 1. Extract audio-only formats
      final audioFormats = formats.where((f) {
        final vcodec = f['vcodec'] as String? ?? 'none';
        final acodec = f['acodec'] as String? ?? 'none';
        final protocol = f['protocol'] as String? ?? '';
        return vcodec == 'none' && acodec != 'none' && !protocol.contains('m3u8');
      }).toList();

      // Find best audio formats by container (m4a/mp4 vs webm/opus)
      dynamic bestM4aAudio;
      dynamic bestWebmAudio;

      for (final f in audioFormats) {
        final ext = f['ext'] as String? ?? '';
        final abr = (f['abr'] as num?)?.toDouble() ?? 0.0;
        if (ext == 'm4a' || ext == 'mp4') {
          if (bestM4aAudio == null || abr > ((bestM4aAudio['abr'] as num?)?.toDouble() ?? 0.0)) {
            bestM4aAudio = f;
          }
        } else if (ext == 'webm') {
          if (bestWebmAudio == null || abr > ((bestWebmAudio['abr'] as num?)?.toDouble() ?? 0.0)) {
            bestWebmAudio = f;
          }
        }
      }

      // Default audio fallback
      final bestAudioFallback = audioFormats.isNotEmpty ? audioFormats.first : null;
      final bestM4a = bestM4aAudio ?? bestAudioFallback;
      final bestWebm = bestWebmAudio ?? bestAudioFallback;

      final List<DownloadQualityOption> options = [];

      // 2. Extract video formats (both muxed and video-only)
      final videoFormats = formats.where((f) {
        final vcodec = f['vcodec'] as String? ?? 'none';
        final protocol = f['protocol'] as String? ?? '';
        return vcodec != 'none' && !protocol.contains('m3u8') && f['height'] != null;
      }).toList();

      // Group and find the best format for each unique resolution + container combination
      final Map<String, dynamic> bestVideoMap = {};

      for (final f in videoFormats) {
        final height = f['height'] as int;
        if (height < 240) continue; // Skip extremely low resolution

        final container = f['ext'] as String? ?? '';
        final key = '${height}_$container';

        final tbr = (f['tbr'] as num?)?.toDouble() ?? 0.0;
        final existing = bestVideoMap[key];
        if (existing == null || tbr > ((existing['tbr'] as num?)?.toDouble() ?? 0.0)) {
          bestVideoMap[key] = f;
        }
      }

      // Sort keys by height descending
      final sortedKeys = bestVideoMap.keys.toList()
        ..sort((a, b) {
          final heightA = int.parse(a.split('_')[0]);
          final heightB = int.parse(b.split('_')[0]);
          return heightB.compareTo(heightA);
        });

      for (final key in sortedKeys) {
        final f = bestVideoMap[key]!;
        final height = f['height'] as int;
        final container = f['ext'] as String? ?? '';
        final formatId = f['format_id'] as String;
        final acodec = f['acodec'] as String? ?? 'none';
        final isMuxed = acodec != 'none';

        int size = 0;
        String idOption = '';
        String label = 'Video - ${height}p (${container.toUpperCase()})';

        if (isMuxed) {
          idOption = formatId;
          size = (f['filesize'] as int?) ?? (f['filesize_approx'] as int?) ?? 0;
        } else {
          // Video-only, pair with best audio format of matching container
          final matchedAudio = container == 'webm' ? bestWebm : bestM4a;
          if (matchedAudio != null) {
            idOption = '$formatId+${matchedAudio['format_id']}';
            final vSize = (f['filesize'] as int?) ?? (f['filesize_approx'] as int?) ?? 0;
            final aSize = (matchedAudio['filesize'] as int?) ?? (matchedAudio['filesize_approx'] as int?) ?? 0;
            size = vSize + aSize;
            label += ' [HD]';
          } else {
            idOption = formatId;
            size = (f['filesize'] as int?) ?? (f['filesize_approx'] as int?) ?? 0;
          }
        }

        options.add(DownloadQualityOption(
          id: idOption,
          label: label,
          sizeInBytes: size,
        ));
      }

      // 3. Add Best Audio-only option
      if (bestM4a != null) {
        final aSize = (bestM4a['filesize'] as int?) ?? (bestM4a['filesize_approx'] as int?) ?? 0;
        options.add(DownloadQualityOption(
          id: 'audio_${bestM4a['format_id']}',
          label: 'Audio Only (${bestM4a['ext'].toString().toUpperCase()})',
          sizeInBytes: aSize,
        ));
      } else if (bestAudioFallback != null) {
        final aSize = (bestAudioFallback['filesize'] as int?) ?? (bestAudioFallback['filesize_approx'] as int?) ?? 0;
        options.add(DownloadQualityOption(
          id: 'audio_${bestAudioFallback['format_id']}',
          label: 'Audio Only (${bestAudioFallback['ext'].toString().toUpperCase()})',
          sizeInBytes: aSize,
        ));
      }

      if (options.isEmpty) {
        options.add(DownloadQualityOption(
          id: 'best',
          label: 'Best Quality',
          sizeInBytes: -1,
        ));
      }

      return options;
    } catch (e) {
      print('OmniDL [YoutubeDownloadPlugin] Error loading quality options: $e');
      return [
        DownloadQualityOption(
          id: 'best',
          label: 'Best Quality',
          sizeInBytes: -1,
        ),
      ];
    }
  }

  @override
  Stream<DownloadStatusUpdate> download(
    DownloadTask task, {
    required String saveDirectory,
  }) {
    final controller = StreamController<DownloadStatusUpdate>();
    
    _executeDownloadWithYtdlp(task, controller);
    
    return controller.stream;
  }

  Future<void> _executeDownloadWithYtdlp(
    DownloadTask task,
    StreamController<DownloadStatusUpdate> controller,
  ) async {
    Process? process;
    bool isCancelled = false;

    controller.onCancel = () {
      isCancelled = true;
      if (process != null) {
        process!.kill(ProcessSignal.sigterm);
      }
    };

    try {
      final ytdlp = await _getYtdlpExecutable();
      
      String formatArg = 'best';
      if (task.selectedQualityId != null) {
        if (task.selectedQualityId!.startsWith('audio_')) {
          formatArg = task.selectedQualityId!.replaceFirst('audio_', '');
        } else {
          formatArg = task.selectedQualityId!;
        }
      }

      final file = File(task.savePath);
      final directory = Directory(file.parent.path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final args = [
        '--js-runtimes', 'node',
        '--newline',
        '--progress',
        '-f', formatArg,
        '-o', task.savePath,
        task.url,
      ];
      
      print('OmniDL [YoutubeDownloadPlugin] Running: $ytdlp ${args.join(' ')}');
      process = await Process.start(ytdlp, args);

      int streamCount = 0;
      bool isSplit = formatArg.contains('+');
      int totalBytes = task.totalBytes;

      final lineStream = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (isCancelled) break;
        print('OmniDL [YoutubeDownloadPlugin] yt-dlp: $line');

        if (line.contains('[download] Destination:')) {
          streamCount++;
        }

        final progressMatch = RegExp(r'\[download\]\s+(\d+(?:\.\d+)?)%').firstMatch(line);
        if (progressMatch != null) {
          final pct = double.tryParse(progressMatch.group(1)!) ?? 0.0;
          double progress = pct / 100;

          if (isSplit) {
            if (streamCount <= 1) {
              progress = progress * 0.75;
            } else {
              progress = 0.75 + (progress * 0.24);
            }
          }

          int currentDownloaded = (totalBytes * progress).round();
          if (totalBytes <= 0) {
            final sizeMatch = RegExp(r'\[download\]\s+\d+(?:\.\d+)?%\s+of\s+(\S+)').firstMatch(line);
            if (sizeMatch != null) {
              totalBytes = _parseSizeToBytes(sizeMatch.group(1)!);
              currentDownloaded = (totalBytes * progress).round();
            }
          }

          controller.add(DownloadStatusUpdate(
            downloadedBytes: currentDownloaded,
            totalBytes: totalBytes,
            progress: progress,
            status: DownloadStatus.downloading,
          ));
        }
      }

      final exitCode = await process.exitCode;
      if (isCancelled) return;

      if (exitCode != 0) {
        final stderrContent = await process.stderr.transform(utf8.decoder).join();
        throw Exception('yt-dlp exited with code $exitCode: $stderrContent');
      }

      controller.add(DownloadStatusUpdate(
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        progress: 1.0,
        status: DownloadStatus.completed,
      ));
      await controller.close();

    } catch (e, stack) {
      print('OmniDL [YoutubeDownloadPlugin] Exception caught: $e');
      print('OmniDL [YoutubeDownloadPlugin] StackTrace: $stack');
      
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

  int _parseSizeToBytes(String sizeStr) {
    final match = RegExp(r'([0-9.]+)\s*(\w+)').firstMatch(sizeStr);
    if (match == null) return 0;
    final value = double.tryParse(match.group(1)!) ?? 0.0;
    final unit = match.group(2)!.toLowerCase();
    if (unit.startsWith('k')) return (value * 1024).round();
    if (unit.startsWith('m')) return (value * 1024 * 1024).round();
    if (unit.startsWith('g')) return (value * 1024 * 1024 * 1024).round();
    return value.round();
  }
}
