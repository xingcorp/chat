import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_chat_image_gallery.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _kTestPngBytes = Uint8List.fromList(<int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  15,
  4,
  0,
  9,
  251,
  3,
  253,
  167,
  201,
  94,
  157,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

Widget _buildGallery({
  required List<AppChatImageGalleryItem> items,
  required ValueChanged<int> onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: AppChatImageGallery(
            images: items,
            onImageTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows overlay counter for more than four images',
      (tester) async {
    final items = List<AppChatImageGalleryItem>.generate(
      5,
      (index) => AppChatImageGalleryItem(
        id: 'img_$index',
        url: '',
        localBytes: _kTestPngBytes,
      ),
    );

    await tester.pumpWidget(
      _buildGallery(
        items: items,
        onTap: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('invokes callback with tapped image index', (tester) async {
    int? tappedIndex;
    final items = List<AppChatImageGalleryItem>.generate(
      3,
      (index) => AppChatImageGalleryItem(
        id: 'img_$index',
        url: '',
        localBytes: _kTestPngBytes,
      ),
    );

    await tester.pumpWidget(
      _buildGallery(
        items: items,
        onTap: (index) => tappedIndex = index,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chat_image_tile_1')));
    await tester.pump();

    expect(tappedIndex, 1);
  });

  testWidgets('tapping +N tile opens the first hidden image index',
      (tester) async {
    int? tappedIndex;
    final items = List<AppChatImageGalleryItem>.generate(
      8,
      (index) => AppChatImageGalleryItem(
        id: 'img_$index',
        url: '',
        localBytes: _kTestPngBytes,
      ),
    );

    await tester.pumpWidget(
      _buildGallery(
        items: items,
        onTap: (index) => tappedIndex = index,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chat_image_tile_3')));
    await tester.pump();

    expect(tappedIndex, 4);
  });

  testWidgets('shows upload progress overlay when item is uploading',
      (tester) async {
    final items = <AppChatImageGalleryItem>[
      AppChatImageGalleryItem(
        id: 'img_uploading',
        url: '',
        localBytes: _kTestPngBytes,
        isUploading: true,
        uploadProgress: 0.42,
      ),
    ];

    await tester.pumpWidget(
      _buildGallery(
        items: items,
        onTap: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('42%'), findsOneWidget);
  });
}
