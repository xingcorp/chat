import 'package:flutter_chat_app/core/initialization/download_plugin_initializer_stub.dart'
    if (dart.library.io) 'package:flutter_chat_app/core/initialization/download_plugin_initializer_io.dart';

Future<void> initializeDownloadPlugin() {
  return initializeDownloadPluginImpl();
}
