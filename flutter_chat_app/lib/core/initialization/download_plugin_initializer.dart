import 'download_plugin_initializer_stub.dart'
    if (dart.library.io) 'download_plugin_initializer_io.dart';

Future<void> initializeDownloadPlugin() {
  return initializeDownloadPluginImpl();
}
