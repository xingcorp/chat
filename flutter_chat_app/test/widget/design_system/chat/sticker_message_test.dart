import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:flutter_chat_app/domain/repositories/i_sticker_repository.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/sticker_message.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _FakeStickerRepository implements IStickerRepository {
  _FakeStickerRepository(this._stickersByCode);

  final Map<String, Sticker> _stickersByCode;
  int resolveCalls = 0;
  int loadPackCalls = 0;

  @override
  Future<Either<Failure, List<StickerPack>>> getAvailablePacks() async {
    loadPackCalls += 1;
    return Right<Failure, List<StickerPack>>(<StickerPack>[]);
  }

  @override
  Future<Either<Failure, List<Sticker>>> getRecentlyUsed() async {
    return Right<Failure, List<Sticker>>(<Sticker>[]);
  }

  @override
  Future<void> addToRecentlyUsed(Sticker sticker) async {}

  @override
  Sticker? resolveSticker(String code) {
    resolveCalls += 1;
    return _stickersByCode[code];
  }
}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  final getIt = GetIt.instance;

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders direct url without resolving from repository',
      (tester) async {
    final repository = _FakeStickerRepository(<String, Sticker>{});
    getIt.registerSingleton<IStickerRepository>(repository);

    await tester.pumpWidget(_wrap(const StickerMessageWidget(
      stickerCode: 'https://example.com/sticker.png',
      size: 120,
    )));
    await tester.pump();

    expect(find.byType(AppImage), findsOneWidget);
    expect(repository.resolveCalls, 0);
    expect(repository.loadPackCalls, 0);
  });

  testWidgets('shows error placeholder when sticker code cannot be resolved',
      (tester) async {
    final repository = _FakeStickerRepository(<String, Sticker>{});
    getIt.registerSingleton<IStickerRepository>(repository);

    await tester.pumpWidget(_wrap(const StickerMessageWidget(
      stickerCode: 'unknown_sticker_code',
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(repository.resolveCalls, 2);
    expect(repository.loadPackCalls, 1);
  });
}
