import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/presentation/widgets/common/media_viewer_shortcut_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('escape pops the fullscreen viewer on desktop platforms',
      (tester) async {
    final previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    try {
      await tester.pumpWidget(const _ShortcutHostTestApp());
      await tester.tap(find.text('Open viewer'));
      await tester.pumpAndSettle();

      expect(find.text('Viewer route'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Viewer route'), findsNothing);
      expect(find.text('Home route'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatformOverride;
    }
  });
}

class _ShortcutHostTestApp extends StatelessWidget {
  const _ShortcutHostTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Home route'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MediaViewerShortcutHost(
                            child: Scaffold(
                              body: Center(
                                child: Text('Viewer route'),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open viewer'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
