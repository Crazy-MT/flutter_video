import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:yueshi_player/app/modules/main_video/playback_speed_controls.dart';

class RateStream extends Fake implements PlayerStream {
  final rates = StreamController<double>.broadcast();
  @override
  Stream<double> get rate => rates.stream;
}

class TestPlayer extends Fake implements Player {
  TestPlayer({double rate = 1, bool playing = true})
    : state = PlayerState(rate: rate, playing: playing);

  @override
  PlayerState state;
  @override
  final RateStream stream = RateStream();
  final changes = <double>[];

  @override
  Future<void> setRate(double rate) async {
    changes.add(rate);
    state = state.copyWith(rate: rate);
    stream.rates.add(rate);
  }
}

void main() {
  for (final rate in [0.5, 1.0, 2.0, 3.0]) {
    testWidgets('hold and release restores $rate', (tester) async {
      final player = TestPlayer(rate: rate);
      addTearDown(player.stream.rates.close);
      await tester.pumpWidget(
        MaterialApp(
          home: HoldToSpeed(player: player, child: const SizedBox.expand()),
        ),
      );
      final gesture = await tester.startGesture(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 600));
      expect(player.state.rate, 2);
      expect(find.text('2 倍速播放中'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(player.changes, [2.0, rate]);
      expect(find.text('2 倍速播放中'), findsNothing);
    });
  }

  for (final exit in ['cancel', 'dispose', 'paused', 'drag']) {
    testWidgets('hold handles $exit', (tester) async {
      final player = TestPlayer(rate: 3, playing: exit != 'paused');
      addTearDown(player.stream.rates.close);
      await tester.pumpWidget(
        MaterialApp(
          home: HoldToSpeed(player: player, child: const SizedBox.expand()),
        ),
      );
      final gesture = await tester.startGesture(const Offset(200, 200));
      if (exit == 'drag') {
        await gesture.moveBy(const Offset(100, 0));
      }
      await tester.pump(const Duration(milliseconds: 600));
      if (exit == 'dispose') {
        await tester.pumpWidget(const SizedBox());
      } else if (exit == 'cancel') {
        await gesture.cancel();
      } else {
        await gesture.up();
      }
      await tester.pump();
      expect(player.state.rate, 3);
      expect(
        player.changes,
        exit == 'paused' || exit == 'drag' ? isEmpty : [2.0, 3.0],
      );
    });
  }

  testWidgets('menu selects all supported speeds and updates label', (
    tester,
  ) async {
    final player = TestPlayer();
    addTearDown(player.stream.rates.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlaybackSpeedButton(player: player)),
      ),
    );
    for (final rate in PlaybackSpeedButton.speeds) {
      await tester.tap(find.byType(PopupMenuButton<double>));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<double>), findsNWidgets(4));
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<double>),
          matching: find.text(PlaybackSpeedButton.label(rate)),
        ),
      );
      await tester.pumpAndSettle();
      expect(player.state.rate, rate);
      expect(find.text(PlaybackSpeedButton.label(rate)), findsOneWidget);
    }
  });
}
