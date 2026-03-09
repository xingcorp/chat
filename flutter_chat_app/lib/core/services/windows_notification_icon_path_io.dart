import 'dart:io';

import 'package:path/path.dart' as p;

String? resolveWindowsNotificationIconPath(String assetPath) {
  if (!Platform.isWindows) {
    return null;
  }

  final String executableDirectory =
      File(Platform.resolvedExecutable).parent.path;
  final String candidate = p.joinAll(<String>[
    executableDirectory,
    'data',
    'flutter_assets',
    ...assetPath.split('/'),
  ]);

  if (File(candidate).existsSync()) {
    return candidate;
  }

  return null;
}
