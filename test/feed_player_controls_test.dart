import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:yueshi_player/app/modules/main_video/main_video_controller.dart';
import 'package:yueshi_player/app/modules/main_video/main_video_page.dart';
import 'playback_speed_controls_test.dart' show RateStream;

class FeedStream extends RateStream {
  @override
  Stream<bool> get playing => const Stream.empty();
  @override
  Stream<bool> get buffering => const Stream.empty();
  @override
  Stream<String> get error => const Stream.empty();
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration> get duration => const Stream.empty();
}

class FeedPlayer extends Fake implements Player {
  @override
  PlayerState state = PlayerState(
    playing: true,
    duration: const Duration(minutes: 2),
  );
  @override
  Future<void> setRate(double rate) async {
    state = state.copyWith(rate: rate);
    stream.rates.add(rate);
  }

  @override
  final FeedStream stream = FeedStream();
  final seeks = <Duration>[];
  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
  }

  int taps = 0;
  @override
  Future<void> playOrPause() async {
    taps++;
  }
}

class FeedController extends MainVideoController {
  @override
  final FeedPlayer player = FeedPlayer();
  @override
  Future<void> addLike() async {
    likeCount.value++;
  }
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(320, 568),
  ]) {
    testWidgets('feed fits $size and actions remain usable', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = FeedController();
      addTearDown(controller.player.stream.rates.close);
      controller.currentPath.value = '/videos/测试视频.mp4';
      controller.playlist.value = [File(controller.currentPath.value)];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: FeedPlayerControls(controller: controller),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('测试视频.mp4'), findsOneWidget);
      await tester.tap(find.byTooltip('点赞，当前 0 次'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byTooltip('点赞，当前 1 次'), findsOneWidget);
      expect(controller.player.taps, 0);
      await tester.tapAt(Offset(size.width / 2, 120));
      await tester.pump(const Duration(milliseconds: 350));
      expect(controller.player.taps, 1);
      await tester.pumpWidget(const SizedBox());
      controller.onClose();
    });
  }

  testWidgets('scrubbing previews time and seeks only on release', (
    tester,
  ) async {
    final player = FeedPlayer();
    addTearDown(player.stream.rates.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: FeedProgress(player: player, memoryPoint: 30000)),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(Slider));
    final gesture = await tester.startGesture(
      Offset(rect.center.dx, rect.center.dy),
    );
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(player.seeks, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(player.seeks, hasLength(1));
    expect(player.seeks.single.inSeconds, greaterThan(60));
  });
}
