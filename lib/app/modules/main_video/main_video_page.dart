import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

import 'main_video_controller.dart';
import 'playback_speed_controls.dart';
import 'video_library_page.dart';

class MainVideoPage extends StatelessWidget {
  const MainVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainVideoController>();
    return Obx(
      () => PopScope(
        canPop:
            controller.showVideoLibrary.value || controller.playlist.isEmpty,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) controller.returnToLibrary();
        },
        child: controller.showVideoLibrary.value
            ? VideoLibraryPage(controller: controller)
            : Scaffold(
                backgroundColor: Colors.black,
                body: Obx(
                  () => controller.currentPath.value.isEmpty
                      ? Center(
                          child: FilledButton.icon(
                            onPressed: controller.requestStoragePermission,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('选择文件夹，浏览视频'),
                          ),
                        )
                      : Video(
                          controller: controller.controller,
                          fit: BoxFit.contain,
                          controls: (context) =>
                              FeedPlayerControls(controller: controller),
                        ),
                ),
              ),
      ),
    );
  }
}

/// Owns only the feed gestures, so buttons and the seek bar can win their gestures.
class FeedGestures extends StatefulWidget {
  const FeedGestures({
    super.key,
    required this.onTap,
    required this.onLike,
    required this.onNext,
    required this.onPrevious,
    required this.child,
  });
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Widget child;

  @override
  State<FeedGestures> createState() => _FeedGesturesState();
}

class _FeedGesturesState extends State<FeedGestures> {
  double _distance = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onDoubleTap: widget.onLike,
    onVerticalDragStart: (_) => _distance = 0,
    onVerticalDragUpdate: (details) => _distance += details.delta.dy,
    onVerticalDragEnd: (details) {
      final velocity = details.primaryVelocity ?? 0;
      if (_distance.abs() < 60 && velocity.abs() < 450) return;
      final direction = velocity.abs() >= 450 ? velocity : _distance;
      if (direction < 0) {
        widget.onNext();
      } else {
        widget.onPrevious();
      }
    },
    child: widget.child,
  );
}

class FeedPlayerControls extends StatelessWidget {
  const FeedPlayerControls({super.key, required this.controller});
  final MainVideoController controller;

  @override
  Widget build(BuildContext context) {
    final player = controller.player;
    final fullscreen = isFullscreen(context);
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.space) {
          player.playOrPause();
        } else if (key == LogicalKeyboardKey.arrowDown) {
          controller.playNext();
        } else if (key == LogicalKeyboardKey.arrowUp) {
          controller.playPrev();
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          controller.seekBackward();
        } else if (key == LogicalKeyboardKey.arrowRight) {
          controller.seekForward();
        } else if (key == LogicalKeyboardKey.escape && fullscreen) {
          exitFullscreen(context);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: HoldToSpeed(
        key: ValueKey(controller.currentPath.value),
        player: player,
        child: FeedGestures(
          onTap: player.playOrPause,
          onLike: controller.addLike,
          onNext: controller.playNext,
          onPrevious: controller.playPrev,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black87,
                      ],
                      stops: [0, .2, .55, 1],
                    ),
                  ),
                ),
              ),
              Center(
                child: StreamBuilder<bool>(
                  stream: player.stream.playing,
                  initialData: player.state.playing,
                  builder: (_, snapshot) => snapshot.data == true
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: '继续播放',
                          iconSize: 72,
                          onPressed: player.play,
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white70,
                          ),
                        ),
                ),
              ),
              Center(
                child: StreamBuilder<bool>(
                  stream: player.stream.buffering,
                  initialData: player.state.buffering,
                  builder: (_, snapshot) => snapshot.data == true
                      ? const IgnorePointer(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Center(
                child: StreamBuilder<String>(
                  key: ValueKey(controller.currentPath.value),
                  stream: player.stream.error,
                  builder: (_, snapshot) => snapshot.hasData
                      ? const IgnorePointer(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: Text(
                              '无法播放此文件，向上滑动切换下一条',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: fullscreen ? '退出全屏' : '返回视频列表',
                            onPressed: () => fullscreen
                                ? exitFullscreen(context)
                                : controller.returnToLibrary(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: '更多',
                            onPressed: () => _more(context),
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 16,
                                  bottom: 12,
                                ),
                                child: Obx(
                                  () => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.basename(
                                          controller.currentPath.value,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${controller.currentIndex.value + 1} / ${controller.playlist.length} · 上下滑动切换',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(
                                    () => _action(
                                      Icons.favorite,
                                      '${controller.likeCount.value}',
                                      '点赞，当前 ${controller.likeCount.value} 次',
                                      controller.addLike,
                                      color: controller.likeCount.value > 0
                                          ? const Color(0xffff2c55)
                                          : Colors.white,
                                    ),
                                  ),
                                  _action(
                                    Icons.playlist_play,
                                    '列表',
                                    '播放列表',
                                    controller.showPlaylistSheet,
                                  ),
                                  _action(
                                    Icons.bookmark_outline,
                                    '记忆点',
                                    '保存记忆点',
                                    controller.saveMemoryPoint,
                                  ),
                                  PlaybackSpeedButton(player: player),
                                  _action(
                                    fullscreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    fullscreen ? '退出' : '全屏',
                                    fullscreen ? '退出全屏' : '全屏播放',
                                    () => toggleFullscreen(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => FeedProgress(
                          key: ValueKey(controller.currentPath.value),
                          player: player,
                          memoryPoint: controller.memoryPointMs.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    String tooltip,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 30),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );

  void _more(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff202020),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.white),
              title: const Text('选择文件夹', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                controller.requestStoragePermission();
              },
            ),
            StreamBuilder<double>(
              stream: controller.player.stream.volume,
              initialData: controller.player.state.volume,
              builder: (_, snapshot) => ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.white),
                title: Slider(
                  value: (snapshot.data ?? 100).clamp(0, 100),
                  max: 100,
                  semanticFormatterCallback: (value) => '音量 ${value.round()}%',
                  onChanged: controller.player.setVolume,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedProgress extends StatefulWidget {
  const FeedProgress({
    super.key,
    required this.player,
    required this.memoryPoint,
  });
  final Player player;
  final int memoryPoint;

  @override
  State<FeedProgress> createState() => _FeedProgressState();
}

class _FeedProgressState extends State<FeedProgress> {
  double? _scrub;

  String _time(Duration value) {
    final seconds = value.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration>(
    stream: widget.player.stream.position,
    initialData: widget.player.state.position,
    builder: (_, snapshot) => StreamBuilder<Duration>(
      stream: widget.player.stream.duration,
      initialData: widget.player.state.duration,
      builder: (_, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final max = duration.inMilliseconds.toDouble();
        final value =
            (_scrub ??
                    (snapshot.data ?? Duration.zero).inMilliseconds.toDouble())
                .clamp(0.0, max > 0 ? max : 1.0);
        final position = Duration(milliseconds: value.round());
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: _scrub == null ? 2 : 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    min: 0,
                    max: max > 0 ? max : 1,
                    value: value,
                    semanticFormatterCallback: (value) =>
                        _time(Duration(milliseconds: value.round())),
                    onChanged: max > 0
                        ? (value) => setState(() => _scrub = value)
                        : null,
                    onChangeEnd: (value) {
                      widget.player.seek(Duration(milliseconds: value.round()));
                      setState(() => _scrub = null);
                    },
                  ),
                  if (widget.memoryPoint > 0 && widget.memoryPoint <= max)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Align(
                            alignment: Alignment(
                              widget.memoryPoint / max * 2 - 1,
                              0,
                            ),
                            child: const SizedBox(
                              width: 3,
                              height: 12,
                              child: ColoredBox(color: Colors.amber),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    _time(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    _time(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
