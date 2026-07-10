import 'package:flutter_test/flutter_test.dart';
import 'package:omnidl/features/downloader/application/downloader_plugin_registry.dart';
import 'package:omnidl/features/downloader/data/plugins/http_download_plugin.dart';

void main() {
  group('Downloader Plugins Tests', () {
    test('Registry can find http plugin', () {
      final registry = DownloaderPluginRegistry.instance;
      final plugin = registry.findPlugin('https://example.com/file.mp4');
      
      expect(plugin, isA<HttpDownloadPlugin>());
    });

    test('HTTP plugin canHandle returns true for http/https', () {
      final plugin = HttpDownloadPlugin();
      
      expect(plugin.canHandle('https://example.com/file.mp4'), isTrue);
      expect(plugin.canHandle('http://example.com/file.mp3'), isTrue);
      expect(plugin.canHandle('ftp://example.com/file.mp4'), isFalse);
      expect(plugin.canHandle('invalid_url'), isFalse);
    });
  });
}
