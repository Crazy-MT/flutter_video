import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yueshi_player/app/modules/main_video/video_likes.dart';

void main() {
  sqfliteFfiInit();
  test(
    'likes persist after reopening and concurrent increments are atomic',
    () async {
      final directory = await Directory.systemTemp.createTemp('video-likes-');
      final path = '${directory.path}/likes.db';
      final store = VideoLikes(factory: databaseFactoryFfi, path: path);
      final video = '/videos/一条\'视频.mp4';
      try {
        expect(await store.count(video), 0);
        final counts = await Future.wait(
          List.generate(20, (_) => store.increment(video)),
        );
        expect(counts.toSet(), Set.from(List.generate(20, (i) => i + 1)));
        expect(await store.count('/videos/other.mp4'), 0);
        await store.close();
        expect(await store.count(video), 20);
        expect(await store.increment('/videos/other.mp4'), 1);
        await expectLater(store.increment(''), throwsArgumentError);
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
