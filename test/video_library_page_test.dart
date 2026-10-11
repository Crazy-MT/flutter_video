import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yueshi_player/app/modules/main_video/main_video_controller.dart';
import 'package:yueshi_player/app/modules/main_video/video_library_page.dart';

class LibraryController extends MainVideoController {
  int? selected;
  @override
  void playIndex(int index) => selected = index;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('click to play and restore library scroll position', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          MainVideoController.platform,
          (_) async => null,
        );
    final controller = LibraryController();
    controller.playlist.value = [
      File('/videos/one.mp4'),
      File('/videos/two.unknown'),
    ];
    await tester.pumpWidget(
      MaterialApp(home: VideoLibraryPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('视频列表'), findsOneWidget);
    expect(find.text('one.mp4'), findsOneWidget);
    expect(find.text('two.unknown'), findsOneWidget);
    expect(controller.selected, isNull);
    await tester.tap(find.text('two.unknown'));
    expect(controller.selected, 1);
    await tester.pumpWidget(const SizedBox());
    controller.onClose();
    {
      final controller = LibraryController();
      controller.playlist.value = List.generate(
        20,
        (index) => File('/scroll/video$index.mp4'),
      );
      final visible = ValueNotifier(true);
      final bucket = PageStorageBucket();
      await tester.pumpWidget(
        MaterialApp(
          home: PageStorage(
            bucket: bucket,
            child: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, show, _) => show
                  ? VideoLibraryPage(controller: controller)
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      final offset = controller.libraryScrollController.offset;
      expect(offset, greaterThan(0));
      visible.value = false;
      await tester.pumpAndSettle();
      visible.value = true;
      await tester.pumpAndSettle();
      expect(controller.libraryScrollController.offset, closeTo(offset, 1));
      await tester.pumpWidget(const SizedBox());
      visible.dispose();
      controller.onClose();
    }
  });
}
