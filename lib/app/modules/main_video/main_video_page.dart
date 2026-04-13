import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'main_video_controller.dart';
import 'package:yueshi_player/common/components/status_page/status_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainVideoPage extends StatefulWidget {
  const MainVideoPage({Key? key}) : super(key: key);

  @override
  State<MainVideoPage> createState() => _MainVideoPageState();
}

class _MainVideoPageState extends State<MainVideoPage> {
  late final MainVideoController controller;
  Timer? _hideBottomToolsTimer;
  bool _showBottomTools = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MainVideoController>();
  }

  @override
  void dispose() {
    _hideBottomToolsTimer?.cancel();
    super.dispose();
  }

  void _showBottomToolsTemporarily() {
    if (!_showBottomTools) {
      setState(() {
        _showBottomTools = true;
      });
    }
    _hideBottomToolsTimer?.cancel();
    _hideBottomToolsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showBottomTools = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            controller.seekBackward();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            controller.seekForward();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // appBar: CommonAppBar(
        //   titleText: 'MainVideo',
        //   centerTitle: true,
        //   actions: [
        //     IconButton(onPressed: controller.playPrev, icon: const Icon(Icons.skip_previous)),
        //     IconButton(onPressed: controller.playNext, icon: const Icon(Icons.skip_next)),
        //   ],
        // ),
        body: Obx(
          () => FTStatusPage(
            type: controller.pageStatus.value,
            enablePullDown: true,
            enablePullUp: true,
            controller: controller.refreshController,
            onLoading: () {
              //controller.getCommissionRecord(isRefresh: false);
            },
            onRefresh: () async {
              //controller.getCommissionRecord();
            },
            errorMsg: controller.errorMsg.value,
            builder: (BuildContext context) {
              return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _showBottomToolsTemporarily(),
                  child: Stack(
                    children: [
                      Obx(() => Center(
                            child: controller.currentPath.value.isEmpty
                                ? InkWell(
                                    onTap: () {
                                      controller.requestStoragePermission();
                                    },
                                    child: const Text(
                                      '还没有接收到视频\n从文件管理器打开一个视频吧～',
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : MaterialDesktopVideoControlsTheme(
                                    normal:
                                        MaterialDesktopVideoControlsThemeData(
                                      bottomButtonBar: [
                                        const MaterialDesktopSkipPreviousButton(),
                                        const MaterialDesktopPlayOrPauseButton(),
                                        const MaterialDesktopSkipNextButton(),
                                        const MaterialDesktopVolumeButton(),
                                        Expanded(
                                          child: _VideoFileNameLabel(
                                            controller: controller,
                                          ),
                                        ),
                                        const MaterialDesktopPositionIndicator(),
                                        const Spacer(),
                                        const MaterialDesktopFullscreenButton(),
                                      ],
                                    ),
                                    fullscreen:
                                        MaterialDesktopVideoControlsThemeData(
                                      topButtonBar: [
                                        const Spacer(),
                                        MaterialCustomButton(
                                          icon: const Icon(Icons.skip_previous),
                                          onPressed: controller.playPrev,
                                        ),
                                        MaterialCustomButton(
                                          icon: const Icon(Icons.skip_next),
                                          onPressed: controller.playNext,
                                        ),
                                        MaterialCustomButton(
                                          icon: const Icon(Icons.list),
                                          onPressed:
                                              controller.showPlaylistSheet,
                                        ),
                                      ],
                                      bottomButtonBar: [
                                        const MaterialDesktopSkipPreviousButton(),
                                        const MaterialDesktopPlayOrPauseButton(),
                                        const MaterialDesktopSkipNextButton(),
                                        const MaterialDesktopVolumeButton(),
                                        Expanded(
                                          child: _VideoFileNameLabel(
                                            controller: controller,
                                          ),
                                        ),
                                        const MaterialDesktopPositionIndicator(),
                                        const Spacer(),
                                        const MaterialDesktopFullscreenButton(),
                                      ],
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 30),
                                      child: MaterialVideoControlsTheme(
                                        normal: MaterialVideoControlsThemeData(
                                          seekGesture: true,
                                          bottomButtonBar: [
                                            Expanded(
                                              child: _VideoFileNameLabel(
                                                controller: controller,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const MaterialPositionIndicator(),
                                            const Spacer(),
                                            const MaterialFullscreenButton(),
                                          ],
                                        ),
                                        fullscreen:
                                            MaterialVideoControlsThemeData(
                                          seekGesture: true,
                                          topButtonBar: [
                                            const Spacer(),
                                            MaterialCustomButton(
                                              icon: const Icon(
                                                  Icons.skip_previous),
                                              onPressed: controller.playPrev,
                                            ),
                                            MaterialCustomButton(
                                              icon: const Icon(Icons.skip_next),
                                              onPressed: controller.playNext,
                                            ),
                                            MaterialCustomButton(
                                              icon: const Icon(Icons.bookmark),
                                              onPressed:
                                                  controller.saveMemoryPoint,
                                            ),
                                            MaterialCustomButton(
                                              icon: const Icon(Icons.list),
                                              onPressed:
                                                  controller.showPlaylistSheet,
                                            ),
                                          ],
                                          bottomButtonBar: [
                                            Expanded(
                                              child: _VideoFileNameLabel(
                                                controller: controller,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const MaterialPositionIndicator(),
                                            const Spacer(),
                                            const MaterialFullscreenButton(),
                                          ],
                                        ),
                                        child: Video(
                                          controller: controller.controller,
                                          controls: (state) {
                                            return _DoubleTapHandler(
                                              onDoubleTapLeft:
                                                  controller.seekBackward,
                                              onDoubleTapRight:
                                                  controller.seekForward,
                                              child: Stack(
                                                children: [
                                                  AdaptiveVideoControls(state),
                                                  IgnorePointer(
                                                    child:
                                                        Obx(
                                                            () =>
                                                                AnimatedOpacity(
                                                                  opacity: controller
                                                                          .showSeekFeedback
                                                                          .value
                                                                      ? 1.0
                                                                      : 0.0,
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          200),
                                                                  child: Center(
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              24,
                                                                          vertical:
                                                                              12),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .black54,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        controller
                                                                            .seekFeedback
                                                                            .value,
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              32,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )),
                                                  ),
                                                  _HidePlaylistOnInteract(
                                                    controller: controller,
                                                  ),
                                                  _MemoryPointMarker(
                                                    controller: controller,
                                                    player: state.widget
                                                        .controller.player,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                          )),
                      // ✅ 半透明播放列表（覆盖在右边）
                      Obx(() => Visibility(
                          visible: controller.showPlaylist.value,
                          child: Positioned(
                            top: Get.height * 0.2,
                            right: 0,
                            height: Get.height * 0.6,
                            width: 250,
                            // 固定宽度
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Column(
                                children: [
                                  // 顶部关闭按钮
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () =>
                                          controller.showPlaylist.value = false,
                                    ),
                                  ),

                                  Expanded(
                                    child: Obx(() => controller
                                            .treePlaylist.isEmpty
                                        ? const Center(
                                            child: Text(
                                              '暂无视频文件',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                        : ListView.builder(
                                            controller: controller
                                                .playlistScrollController,
                                            itemCount:
                                                controller.treePlaylist.length,
                                            itemBuilder:
                                                (context, folderIndex) {
                                              final folderData = controller
                                                  .treePlaylist[folderIndex];
                                              final folderName =
                                                  folderData['folder']
                                                      as String;
                                              final files =
                                                  folderData['files'] as List;
                                              final isExpanded =
                                                  folderData['isExpanded']
                                                      as RxBool;

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 文件夹标题（可点击展开/折叠）
                                                  if (folderName != '.')
                                                    InkWell(
                                                      onTap: () {
                                                        isExpanded.value =
                                                            !isExpanded.value;
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        color: Colors.white
                                                            .withOpacity(0.1),
                                                        child: Row(
                                                          children: [
                                                            Obx(() => Icon(
                                                                  isExpanded
                                                                          .value
                                                                      ? Icons
                                                                          .folder_open
                                                                      : Icons
                                                                          .folder,
                                                                  color: Colors
                                                                      .amber,
                                                                  size: 20,
                                                                )),
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                folderName,
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .amber,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            Obx(() => Icon(
                                                                  isExpanded
                                                                          .value
                                                                      ? Icons
                                                                          .expand_less
                                                                      : Icons
                                                                          .expand_more,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 20,
                                                                )),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  // 文件列表
                                                  Obx(() => Visibility(
                                                        visible:
                                                            isExpanded.value,
                                                        child: Column(
                                                          children: files
                                                              .map<Widget>(
                                                                  (file) {
                                                            final filePath =
                                                                file.path;
                                                            final fileName =
                                                                filePath
                                                                    .split('/')
                                                                    .last;
                                                            final globalIndex =
                                                                controller
                                                                    .playlist
                                                                    .indexWhere((e) =>
                                                                        e.path ==
                                                                        filePath);

                                                            return ListTile(
                                                              dense: true,
                                                              contentPadding:
                                                                  EdgeInsets.only(
                                                                      left: folderName ==
                                                                              '.'
                                                                          ? 12
                                                                          : 32,
                                                                      right: 8),
                                                              title: Text(
                                                                fileName,
                                                                style:
                                                                    TextStyle(
                                                                  color: (globalIndex ==
                                                                          controller
                                                                              .currentIndex
                                                                              .value)
                                                                      ? Colors
                                                                          .amber
                                                                      : Colors
                                                                          .white,
                                                                  fontSize: 13,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              trailing:
                                                                  IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 18),
                                                                onPressed: () {
                                                                  if (globalIndex >=
                                                                      0) {
                                                                    controller
                                                                        .showDeleteConfirmDialog(
                                                                            globalIndex);
                                                                  }
                                                                },
                                                              ),
                                                              onTap: () {
                                                                if (globalIndex >=
                                                                    0) {
                                                                  controller
                                                                      .playIndex(
                                                                          globalIndex);
                                                                }
                                                              },
                                                            );
                                                          }).toList(),
                                                        ),
                                                      )),
                                                ],
                                              );
                                            },
                                          )),
                                  ),
                                ],
                              ),
                            ),
                          ))),

                      Obx(() {
                        final canSwitch = controller.playlist.isNotEmpty;
                        final canMark = controller.currentPath.value.isNotEmpty;
                        if (!_showBottomTools) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          left: 0,
                          right: 0,
                          bottom: 60,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              FloatingActionButton(
                                heroTag: 'prev',
                                mini: true,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                onPressed:
                                    canSwitch ? controller.playPrev : null,
                                child: const Icon(Icons.skip_previous,
                                    color: Colors.white),
                              ),
                              FloatingActionButton(
                                heroTag: 'list',
                                mini: true,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                onPressed: canSwitch
                                    ? controller.togglePlaylistPanel
                                    : null,
                                child:
                                    const Icon(Icons.list, color: Colors.white),
                              ),
                              FloatingActionButton(
                                heroTag: 'folder',
                                mini: true,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                onPressed: controller.requestStoragePermission,
                                child: const Icon(Icons.folder_open,
                                    color: Colors.white),
                              ),
                              FloatingActionButton(
                                heroTag: 'shuffle',
                                mini: true,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                onPressed: controller.toggleShuffleMode,
                                child: Obx(() => Icon(
                                      controller.isShuffleMode.value
                                          ? Icons.shuffle
                                          : Icons.shuffle_outlined,
                                      color: controller.isShuffleMode.value
                                          ? Colors.amber
                                          : Colors.white,
                                    )),
                              ),
                              FloatingActionButton(
                                heroTag: 'bookmark',
                                mini: true,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                onPressed:
                                    canMark ? controller.saveMemoryPoint : null,
                                child: const Icon(Icons.bookmark,
                                    color: Colors.white),
                              ),
                              FloatingActionButton(
                                heroTag: 'next',
                                mini: true,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                onPressed:
                                    canSwitch ? controller.playNext : null,
                                child: const Icon(Icons.skip_next,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }),
                      // 双击检测层 - 放在最下面确保能接收事件
                    ],
                  ));
            },
          ),
        ),
      ),
    );
  }
}

class _MemoryPointMarker extends StatelessWidget {
  const _MemoryPointMarker({
    required this.controller,
    required this.player,
  });

  final MainVideoController controller;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final memoryMs = controller.memoryPointMs.value;
      if (memoryMs <= 0) {
        return const SizedBox.shrink();
      }
      final isFullscreen = FullscreenInheritedWidget.maybeOf(context) != null;
      final platform = Theme.of(context).platform;
      final useDesktopTheme = platform == TargetPlatform.macOS ||
          platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux;
      final materialTheme = isFullscreen
          ? MaterialVideoControlsTheme.maybeOf(context)?.fullscreen ??
              const MaterialVideoControlsThemeData()
          : MaterialVideoControlsTheme.maybeOf(context)?.normal ??
              const MaterialVideoControlsThemeData();
      final desktopTheme = isFullscreen
          ? MaterialDesktopVideoControlsTheme.maybeOf(context)?.fullscreen ??
              const MaterialDesktopVideoControlsThemeData()
          : MaterialDesktopVideoControlsTheme.maybeOf(context)?.normal ??
              const MaterialDesktopVideoControlsThemeData();
      final seekBarMargin = useDesktopTheme
          ? desktopTheme.seekBarMargin
          : materialTheme.seekBarMargin;
      final seekBarContainerHeight = useDesktopTheme
          ? desktopTheme.seekBarContainerHeight
          : materialTheme.seekBarContainerHeight;
      final seekBarHeight = useDesktopTheme
          ? desktopTheme.seekBarHeight
          : materialTheme.seekBarHeight;
      final seekBarAlignment = useDesktopTheme
          ? Alignment.centerLeft
          : materialTheme.seekBarAlignment;
      return StreamBuilder<Duration>(
        stream: player.stream.duration,
        initialData: player.state.duration,
        builder: (context, snapshot) {
          final duration = snapshot.data;
          if (duration == null || duration.inMilliseconds <= 0) {
            return const SizedBox.shrink();
          }
          if (memoryMs > duration.inMilliseconds) {
            return const SizedBox.shrink();
          }
          return Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: seekBarMargin,
                child: Align(
                  alignment: seekBarAlignment,
                  child: SizedBox(
                    height: seekBarContainerHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        if (barWidth <= 0) {
                          return const SizedBox.shrink();
                        }
                        final ratio = memoryMs / duration.inMilliseconds;
                        const markerWidth = 3.0;
                        final left = (barWidth * ratio - markerWidth / 2)
                            .clamp(0.0, barWidth);
                        final normalizedY = (seekBarAlignment.y + 1) / 2;
                        final top = (seekBarContainerHeight - seekBarHeight) *
                            normalizedY;
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Positioned(
                              left: left,
                              top: top,
                              child: Container(
                                width: markerWidth,
                                height: seekBarHeight,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _VideoFileNameLabel extends StatelessWidget {
  const _VideoFileNameLabel({
    required this.controller,
  });

  final MainVideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final path = controller.currentPath.value;
      if (path.isEmpty) {
        return const SizedBox.shrink();
      }
      final name = path.split('/').last;
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );
    });
  }
}

class _HidePlaylistOnInteract extends StatelessWidget {
  const _HidePlaylistOnInteract({
    required this.controller,
  });

  final MainVideoController controller;

  void _hide() {
    if (controller.showPlaylist.value) {
      controller.showPlaylist.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showPlaylist.value) {
        return const SizedBox.shrink();
      }
      return Positioned.fill(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _hide(),
          onPointerSignal: (_) => _hide(),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

class _DoubleTapHandler extends StatefulWidget {
  const _DoubleTapHandler({
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.child,
  });

  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final Widget child;

  @override
  State<_DoubleTapHandler> createState() => _DoubleTapHandlerState();
}

class _DoubleTapHandlerState extends State<_DoubleTapHandler> {
  DateTime? _lastTapTime;
  double? _lastTapX;

  static const _doubleTapDuration = Duration(milliseconds: 300);

  void _handleTap(PointerDownEvent event) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapDuration) {
      final width = context.size?.width ?? 0;
      if (_lastTapX! < width / 2) {
        widget.onDoubleTapLeft();
      } else {
        widget.onDoubleTapRight();
      }
      _lastTapTime = null;
      _lastTapX = null;
    } else {
      _lastTapTime = now;
      _lastTapX = event.localPosition.dx;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
