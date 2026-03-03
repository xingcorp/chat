import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/presence_indicator.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testHost(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('shows online text when user is online', (tester) async {
    await tester.pumpWidget(
      _testHost(
        LivePresenceIndicator(
          userId: 'user_1',
          presenceStream: Stream<UserPresence>.value(
            const UserPresence(
              userId: 'user_1',
              isOnline: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('shows last seen text when user is offline', (tester) async {
    final lastSeen = DateTime.now().subtract(const Duration(minutes: 10));

    await tester.pumpWidget(
      _testHost(
        LivePresenceIndicator(
          userId: 'user_2',
          presenceStream: Stream<UserPresence>.value(
            UserPresence(
              userId: 'user_2',
              isOnline: false,
              lastSeen: lastSeen,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Last seen'), findsOneWidget);
  });

  testWidgets('shows loading state while waiting for first presence value',
      (tester) async {
    final controller = StreamController<UserPresence>.broadcast();
    addTearDown(() async {
      await controller.close();
    });

    await tester.pumpWidget(
      _testHost(
        LivePresenceIndicator(
          userId: 'user_3',
          presenceStream: controller.stream,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppProgressIndicator), findsOneWidget);
  });

  testWidgets('falls back to offline when stream has error', (tester) async {
    await tester.pumpWidget(
      _testHost(
        LivePresenceIndicator(
          userId: 'user_4',
          presenceStream: Stream<UserPresence>.error(Exception('stream error')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Offline'), findsOneWidget);
  });
}
