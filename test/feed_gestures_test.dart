import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yueshi_player/app/modules/main_video/main_video_page.dart';
import 'package:yueshi_player/app/modules/main_video/main_video_controller.dart';

class SequenceController extends MainVideoController {
  @override
  void playIndex(int index) {
    currentIndex.value = index;
  }
}

void main() {
  test('next and previous follow file order and wrap at the boundaries', () {
    final controller = SequenceController();
    controller.playNext();
    expect(controller.currentIndex.value, 0);
    controller.playlist.value = [File('a'), File('b'), File('c')];
    for (final expected in [1, 2, 0]) {
      controller.playNext();
      expect(controller.currentIndex.value, expected);
    }
    controller.playPrev();
    expect(controller.currentIndex.value, 2);
    controller.onClose();
  });

  test('completion advances once and never advances while library is open', () {
    final controller = SequenceController();
    controller.playlist.value = [File('a'), File('b'), File('c')];
    controller.onPlaybackCompleted(false);
    expect(controller.currentIndex.value, 0);
    controller.showVideoLibrary.value = true;
    controller.onPlaybackCompleted(true);
    expect(controller.currentIndex.value, 0);
    controller.showVideoLibrary.value = false;
    controller.onPlaybackCompleted(true);
    expect(controller.currentIndex.value, 1);
    controller.onPlaybackCompleted(true);
    expect(controller.currentIndex.value, 1);
    controller.onClose();
  });

  testWidgets(
    'tap pauses; up/down switch once; small drag and buttons do not switch',
    (tester) async {
      var taps = 0;
      var next = 0;
      var previous = 0;
      var buttons = 0;
      var likes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FeedGestures(
            onTap: () => taps++,
            onLike: () => likes++,
            onNext: () => next++,
            onPrevious: () => previous++,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TextButton(
                onPressed: () => buttons++,
                child: const Text('列表'),
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 350));
      expect(taps, 1);
      await tester.dragFrom(const Offset(200, 300), const Offset(0, -150));
      expect(next, 1);
      await tester.dragFrom(const Offset(200, 200), const Offset(0, 150));
      expect(previous, 1);
      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      expect(next, 1);
      expect(previous, 1);
      await tester.tap(find.text('列表'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(buttons, 1);
      expect(taps, 1);
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 350));
      expect(likes, 1);
      expect(taps, 1);
    },
  );
}
