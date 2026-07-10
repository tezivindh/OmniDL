import 'package:flutter_test/flutter_test.dart';
import 'package:omnidl/features/downloader/application/downloader_plugin_registry.dart';
import 'package:omnidl/features/downloader/data/plugins/http_download_plugin.dart';
import 'package:omnidl/features/downloader/data/plugins/youtube_download_plugin.dart';

void main() {
  group('Downloader Plugins Tests', () {
    test('Registry can find http and youtube plugins', () {
      final registry = DownloaderPluginRegistry.instance;
      
      final httpPlugin = registry.findPlugin('https://example.com/file.mp4');
      expect(httpPlugin, isA<HttpDownloadPlugin>());

      final ytPlugin1 = registry.findPlugin('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(ytPlugin1, isA<YoutubeDownloadPlugin>());

      final ytPlugin2 = registry.findPlugin('https://youtu.be/dQw4w9WgXcQ');
      expect(ytPlugin2, isA<YoutubeDownloadPlugin>());
    });

    test('HTTP plugin canHandle returns true for http/https', () {
      final plugin = HttpDownloadPlugin();
      
      expect(plugin.canHandle('https://example.com/file.mp4'), isTrue);
      expect(plugin.canHandle('http://example.com/file.mp3'), isTrue);
      expect(plugin.canHandle('ftp://example.com/file.mp4'), isFalse);
      expect(plugin.canHandle('invalid_url'), isFalse);
    });

    test('YouTube plugin canHandle returns true for youtube urls', () {
      final plugin = YoutubeDownloadPlugin();
      
      expect(plugin.canHandle('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
      expect(plugin.canHandle('https://youtu.be/dQw4w9WgXcQ'), isTrue);
      expect(plugin.canHandle('https://youtube-nocookie.com/embed/dQw4w9WgXcQ'), isTrue);
      expect(plugin.canHandle('https://example.com/file.mp4'), isFalse);
    });
  });
}
