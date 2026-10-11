import 'dart:typed_data';
import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import 'main_video_controller.dart';

class VideoLibraryPage extends StatelessWidget {
  const VideoLibraryPage({super.key, required this.controller});

  final MainVideoController controller;
  static final Map<String, Future<Uint8List?>> _thumbnails = {};

  static Future<void> _thumbnailQueue = Future<void>.value();

  static Future<Uint8List?> _thumbnail(String path) {
    final result = _thumbnailQueue.then((_) => _readFirstFrame(path));
    _thumbnailQueue = result.then<void>((_) {});
    return result;
  }

  static Future<Uint8List?> _readFirstFrame(String path) async {
    try {
      if (!Platform.isAndroid) {
        final player = Player();
        final video = VideoController(player);
        try {
          await video.platform.future.timeout(const Duration(seconds: 5));
          await player.open(Media(path), play: false);
          for (var attempt = 0; attempt < 20; attempt++) {
            final bytes = await player.screenshot();
            if (bytes != null) return bytes;
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          return null;
        } finally {
          await player.dispose();
        }
      }
      return await MainVideoController.platform.invokeMethod<Uint8List>(
        'videoFirstFrame',
        {'path': path},
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff111111),
      appBar: AppBar(
        title: const Text('视频列表'),
        backgroundColor: const Color(0xff111111),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: '选择文件夹',
            onPressed: controller.requestStoragePermission,
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Obx(() {
        final files = controller.playlist.toList();
        if (files.isEmpty) {
          return const Center(
            child: Text('文件夹中没有文件', style: TextStyle(color: Colors.white70)),
          );
        }
        return SingleChildScrollView(
          key: PageStorageKey(
            'video-library:${files.first.path}:${files.length}',
          ),
          controller: controller.libraryScrollController,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              2,
              (column) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: column == 0 ? 0 : 6,
                    right: column == 0 ? 6 : 0,
                  ),
                  child: Column(
                    children: [
                      for (var index = column; index < files.length; index += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Material(
                              color: const Color(0xff252525),
                              child: InkWell(
                                onTap: () => controller.playIndex(index),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    FutureBuilder<Uint8List?>(
                                      future: _thumbnails.putIfAbsent(
                                        files[index].path,
                                        () => _thumbnail(files[index].path),
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.data != null) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.fitWidth,
                                            gaplessPlayback: true,
                                          );
                                        }
                                        return SizedBox(
                                          height: 140,
                                          child: Center(
                                            child:
                                                snapshot.connectionState ==
                                                    ConnectionState.done
                                                ? const Icon(
                                                    Icons.video_file_outlined,
                                                    color: Colors.white54,
                                                    size: 40,
                                                  )
                                                : const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        p.basename(files[index].path),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
