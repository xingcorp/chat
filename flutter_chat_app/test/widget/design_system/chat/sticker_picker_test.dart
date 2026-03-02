import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:flutter_chat_app/domain/repositories/i_sticker_repository.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/sticker_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _FakeStickerRepository implements IStickerRepository {
  _FakeStickerRepository({
    required this.packs,
    required this.recent,
  });

  final List<StickerPack> packs;
  List<Sticker> recent;
  final List<String> addedCodes = <String>[];
  int resolveCalls = 0;

  @override
  Future<Either<Failure, List<StickerPack>>> getAvailablePacks() async {
    return Right<Failure, List<StickerPack>>(packs);
  }

  @override
  Future<Either<Failure, List<Sticker>>> getRecentlyUsed() async {
    return Right<Failure, List<Sticker>>(recent);
  }

  @override
  Future<void> addToRecentlyUsed(Sticker sticker) async {
    addedCodes.add(sticker.code);
    recent = <Sticker>[
      sticker,
      ...recent.where((item) => item.code != sticker.code)
    ];
  }

  @override
  Sticker? resolveSticker(String code) {
    resolveCalls += 1;
    for (final pack in packs) {
      for (final sticker in pack.stickers) {
        if (sticker.code == code) {
          return sticker;
        }
      }
    }
    return null;
  }
}

Widget _hostWidget(ValueChanged<Sticker> onSelected) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open_picker_button'),
              onPressed: () {
                StickerPickerBottomSheet.show(
                  context,
                  onStickerSelected: onSelected,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final getIt = GetIt.instance;

  Future<void> settlePicker(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows tabs and sends selected sticker immediately',
      (tester) async {
    final repository = _FakeStickerRepository(
      packs: const <StickerPack>[
        StickerPack(
          id: 'emotion_classic',
          name: 'Classic',
          thumbnailUrl: 'https://example.com/classic.png',
          stickers: <Sticker>[
            Sticker(
                code: 'emotion_classic_happy',
                imageUrl: 'https://example.com/happy.png'),
            Sticker(
                code: 'emotion_classic_sad',
                imageUrl: 'https://example.com/sad.png'),
          ],
        ),
      ],
      recent: const <Sticker>[],
    );
    getIt.registerSingleton<IStickerRepository>(repository);

    Sticker? selected;
    await tester.pumpWidget(_hostWidget((sticker) {
      selected = sticker;
    }));

    await tester.tap(find.byKey(const Key('open_picker_button')));
    await settlePicker(tester);

    expect(find.byType(StickerPickerBottomSheet), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sticker_tab_emotion_classic')));
    await settlePicker(tester);

    await tester
        .tap(find.byKey(const Key('sticker_item_emotion_classic_happy')));
    await settlePicker(tester);

    expect(selected?.code, 'emotion_classic_happy');
    expect(repository.addedCodes, <String>['emotion_classic_happy']);
    expect(find.byType(StickerPickerBottomSheet), findsNothing);
  });

  testWidgets('shows empty state when no sticker is available', (tester) async {
    final repository = _FakeStickerRepository(
      packs: const <StickerPack>[],
      recent: const <Sticker>[],
    );
    getIt.registerSingleton<IStickerRepository>(repository);

    await tester.pumpWidget(_hostWidget((_) {}));

    await tester.tap(find.byKey(const Key('open_picker_button')));
    await settlePicker(tester);

    expect(find.text('No stickers available'), findsOneWidget);
  });
}
