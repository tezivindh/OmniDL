import 'package:omnidl/features/downloader/data/plugins/http_download_plugin.dart';
import 'package:omnidl/features/downloader/data/plugins/youtube_download_plugin.dart';
import 'package:omnidl/features/downloader/domain/download_plugin.dart';

class DownloaderPluginRegistry {
  DownloaderPluginRegistry._();
  static final DownloaderPluginRegistry instance = DownloaderPluginRegistry._();

  final List<DownloadPlugin> _plugins = [
    YoutubeDownloadPlugin(), // Register YouTube plugin
    HttpDownloadPlugin(),    // Register default HTTP plugin
  ];

  /// Find a plugin that can handle the given URL.
  /// Throws an exception if no plugin can handle the URL.
  DownloadPlugin findPlugin(String url) {
    for (final plugin in _plugins) {
      if (plugin.canHandle(url)) {
        return plugin;
      }
    }
    throw Exception('No plugin found to handle URL: $url');
  }
}
