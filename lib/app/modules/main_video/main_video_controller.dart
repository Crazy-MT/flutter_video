import 'dart:io';
import 'dart:async';
import 'video_likes.dart';

import 'package:yueshi_player/common/common.dart';
import 'package:yueshi_player/utils/log_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:yueshi_player/common/components/status_page/status_page.dart';
import 'package:yueshi_player/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sp_util/sp_util.dart';
// import 'package:uri_to_file/uri_to_file.dart';

import 'package:path/path.dart' as p;

class MainVideoController extends GetxController {
  final likes = VideoLikes();
  final likeCount = 0.obs;
  StreamSubscription<bool>? _completedSubscription;
  int _playRequest = 0;
  Future<void> _openQueue = Future<void>.value();

  Future<void> loadLikes(String path) async {
    likeCount.value = 0;
    try {
      final count = await likes.count(path);
      if (currentPath.value == path && count > likeCount.value) {
        likeCount.value = count;
      }
    } catch (_) {
      if (currentPath.value == path) Utils.showToastMsg('点赞数读取失败，请重试');
    }
  }

  Future<void> addLike() async {
    final path = currentPath.value;
    if (path.isEmpty) return;
    try {
      final count = await likes.increment(path);
      if (currentPath.value == path && count > likeCount.value) {
        likeCount.value = count;
      }
    } catch (_) {
      Utils.showToastMsg('点赞保存失败，请重试');
    }
  }

  final pageName = 'MainVideo'.obs;
  final errorMsg = "".obs;
  final pageStatus = FTStatusPageType.loading.obs;

  //ScrollController scrollController = ScrollController();
  //RxList<InviteRecordDto?> inviteProductList = RxList<InviteRecordDto?>();
  final RefreshController refreshController = new RefreshController();

  int currentPage = 0;

  static const platform = MethodChannel('com.bomanyi.ai/channel');
  var currentPath = ''.obs;
  final showVideoLibrary = false.obs;
  final libraryScrollController = ScrollController();
  // 所有普通文件都按视频尝试解码，不按扩展名或格式筛选。
  var playlist = [].obs;
  var treePlaylist = [].obs; // 树形播放列表数据

  var currentIndex = 0.obs;
  var showPlaylist = false.obs; // 控制是否显示列表
  var memoryPointMs = 0.obs;
  var seekFeedback = ''.obs;
  var showSeekFeedback = false.obs;
  var _hasTriggeredAutoPlay = false; // 防止重复触发自动播放
  final playlistScrollController = ScrollController();
  final playlistSheetScrollController = ScrollController();

  Player? _player;
  Player get player => _player ??= Player();
  late final controller = VideoController(player);

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  initData() async {
    pageStatus.value = FTStatusPageType.success;
    //getCommissionRecord();

    await SpUtil.getInstance();

    await common.initCommon();

    platform.setMethodCallHandler(_handleMethodCall);

    // 监听播放完成事件
    _completedSubscription = player.stream.completed.listen(
      onPlaybackCompleted,
    );

    // requestStoragePermission();
  }

  Future<void> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      pickFolder();
      return;
    }
    if (await Permission.manageExternalStorage.isGranted) {
      print("✅ 已经有读写权限");
      pickFolder();
    } else {
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        print("✅ 权限已获取");
        pickFolder();
      } else if (status.isPermanentlyDenied) {
        print("❌ 用户永久拒绝，请跳转设置页");
        openAppSettings(); // 打开系统设置
      } else {
        print("❌ 权限被拒绝");
      }
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    /*if (call.method == "onVideoReceived") {
      // currentPath.value = call.arguments as String;
      print("📥 收到视频 path: ${call.arguments as String}");
      // 这里你可以跳转到播放页面

      // 转成本地路径
      final file = await File(call.arguments as String);
      // 获取当前目录下所有视频文件
      _loadPlaylist(file);
      // 播放当前这个
      // playFile(currentPath.value);
    }*/

    if (call.method == "onVideoReceivedUri") {
      showVideoLibrary.value = false;
      currentPath.value = call.arguments as String;
      print("📥 收到视频 URI: ${currentPath.value}");
      playFile(currentPath.value);
    }
  }

  void playFile(String path) {
    final request = ++_playRequest;
    _hasTriggeredAutoPlay = true;
    unawaited(loadLikes(path));
    // Serialize native opens so an older file cannot finish after the latest selection.
    _openQueue = _openQueue.then((_) async {
      if (request != _playRequest || isClosed) return;
      try {
        await controller.platform.future;
        if (Platform.isMacOS) {
          await (player.platform as NativePlayer).setProperty(
            'cache-on-disk',
            'no',
          );
        }
        if (request != _playRequest || isClosed) return;
        await player.open(Media(path));
        if (showVideoLibrary.value) {
          await player.pause();
          return;
        }
        if (request != _playRequest || isClosed) return;
        _hasTriggeredAutoPlay = false;
        _loadMemoryPoint(path);
      } catch (_) {
        if (request == _playRequest && !isClosed) {
          Utils.showToastMsg('视频播放失败，请切换下一条');
        }
      }
    });
  }

  void pickFolder() async {
    lLog('MainVideoController.pickFolder');
    try {
      // 针对iOS平台，使用不同的文件选择策略
      if (Platform.isIOS) {
        // 在iOS上，使用文件选择器选择单个文件，然后获取其所在目录
        final result = await FilePicker.platform.pickFiles(
          // type: FileType.video,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          // 获取第一个文件的目录路径
          final firstFile = result.files.first;
          final folderPath = p.dirname(firstFile.path!);
          print('选中的文件夹: $folderPath');
          lLog('MainVideoController.pickFolder 1 ${folderPath} ');

          // 处理选中的文件
          final files = result.files.map((file) => File(file.path!)).toList();

          // 排序
          files.sort((a, b) => _naturalCompare(a.path, b.path));

          // 更新UI
          playlist.value = files;
          lLog('MainVideoController.pickFolder ${playlist} ');

          // 构建树形播放列表
          _buildTreePlaylist(folderPath);

          await showLibrary();
        }
      } else {
        // Android和其他平台使用文件夹选择
        String? folderPath = await FilePicker.platform.getDirectoryPath();
        if (folderPath != null) {
          print('选中的文件夹: $folderPath');
          lLog('MainVideoController.pickFolder 1 ${folderPath} ');

          // 在后台线程执行耗时操作
          await Future.delayed(Duration.zero, () async {
            try {
              final dir = Directory(folderPath);
              lLog('MainVideoController.pickFolder 2 ${folderPath} ');
              final allEntities = dir.listSync(recursive: true);
              lLog('MainVideoController.pickFolder 3 ${folderPath} ');

              // 保留所有文件
              final files = allEntities
                  .where((entity) => entity is File)
                  .toList();

              // 排序
              files.sort((a, b) => _naturalCompare(a.path, b.path));

              // 回到主线程更新UI
              playlist.value = files;
              lLog('MainVideoController.pickFolder ${playlist} ');

              // 构建树形播放列表
              _buildTreePlaylist(folderPath);

              await showLibrary();
            } catch (e) {
              lLog('MainVideoController.pickFolder error: $e');
              Utils.showToastMsg('读取文件夹失败: $e');
            }
          });
        }
      }
    } catch (e) {
      lLog('MainVideoController.pickFolder error: $e');
      Utils.showToastMsg('选择文件夹失败: $e');
    }
  }

  Future<void> showLibrary() async {
    ++_playRequest;
    _hasTriggeredAutoPlay = true;
    await player.stop();
    currentPath.value = '';
    showVideoLibrary.value = true;
    if (libraryScrollController.hasClients) libraryScrollController.jumpTo(0);
  }

  void returnToLibrary() {
    ++_playRequest;
    _hasTriggeredAutoPlay = true;
    player.pause();
    showVideoLibrary.value = true;
  }

  void _buildTreePlaylist(String rootPath) {
    treePlaylist.clear();

    try {
      // 按文件夹分组
      Map<String, List<FileSystemEntity>> folderMap = {};

      if (Platform.isIOS) {
        // 在iOS上，直接使用playlist中的文件
        for (var entity in playlist) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: rootPath);
            final folder = p.dirname(relativePath);
            if (!folderMap.containsKey(folder)) {
              folderMap[folder] = [];
            }
            folderMap[folder]!.add(entity);
          }
        }
      } else {
        // 在Android和其他平台，使用目录遍历
        final dir = Directory(rootPath);
        final entities = dir.listSync(recursive: true);

        for (var entity in entities) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: rootPath);
            final folder = p.dirname(relativePath);
            if (!folderMap.containsKey(folder)) {
              folderMap[folder] = [];
            }
            folderMap[folder]!.add(entity);
          }
        }
      }

      // 构建树形结构
      folderMap.forEach((folder, files) {
        files.sort((a, b) => _naturalCompare(a.path, b.path));
        treePlaylist.add({
          'folder': folder,
          'files': files,
          'isExpanded': true.obs,
        });
      });

      // 排序：根目录文件夹在前
      treePlaylist.sort((a, b) {
        if (a['folder'] == '.') return -1;
        if (b['folder'] == '.') return 1;
        return (a['folder'] as String).compareTo(b['folder'] as String);
      });
    } catch (e) {
      lLog('MainVideoController._buildTreePlaylist error: $e');
      // 如果构建失败，使用简单的列表结构
      if (playlist.isNotEmpty) {
        treePlaylist.add({
          'folder': '.',
          'files': playlist,
          'isExpanded': true.obs,
        });
      }
    }
  }

  static int _naturalCompare(String a, String b) {
    final re = RegExp(r'(\d+|\D+)');
    final aParts = re.allMatches(a).map((m) => m.group(0)!).toList();
    final bParts = re.allMatches(b).map((m) => m.group(0)!).toList();
    final len = aParts.length < bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final aIsNum = aParts[i].contains(RegExp(r'^\d+$'));
      final bIsNum = bParts[i].contains(RegExp(r'^\d+$'));
      if (aIsNum && bIsNum) {
        final cmp = int.parse(aParts[i]).compareTo(int.parse(bParts[i]));
        if (cmp != 0) return cmp;
      } else {
        final cmp = aParts[i].toLowerCase().compareTo(bParts[i].toLowerCase());
        if (cmp != 0) return cmp;
      }
    }
    return aParts.length.compareTo(bParts.length);
  }

  void setPageName(String newName) {
    pageName.value = newName;
  }

  @override
  void onClose() {
    ++_playRequest;
    _completedSubscription?.cancel();
    unawaited(likes.close());
    _player?.dispose();
    libraryScrollController.dispose();
    playlistScrollController.dispose();
    playlistSheetScrollController.dispose();
    super.onClose();
  }

  playIndex(int index) {
    if (playlist.isEmpty) {
      return;
    }
    if (index < 0 || index >= playlist.length) {
      return;
    }
    showVideoLibrary.value = false;
    currentIndex.value = index;
    var path = playlist[index].path;
    currentPath.value = path;
    playFile(path);
  }

  void playPrev() {
    if (playlist.isEmpty) {
      return;
    }
    var nextIndex = currentIndex.value - 1;
    if (nextIndex < 0) {
      nextIndex = playlist.length - 1;
    }
    playIndex(nextIndex);
  }

  void playNext() {
    if (playlist.isEmpty) {
      return;
    }
    var nextIndex = currentIndex.value + 1;
    if (nextIndex >= playlist.length) {
      nextIndex = 0;
    }
    playIndex(nextIndex);
  }

  void onPlaybackCompleted(bool completed) {
    if (!completed ||
        playlist.isEmpty ||
        _hasTriggeredAutoPlay ||
        showVideoLibrary.value) {
      return;
    }
    _hasTriggeredAutoPlay = true;
    _onPlaybackCompleted();
  }

  void _onPlaybackCompleted() {
    // 播放完成时自动播放下一个
    if (!showVideoLibrary.value) playNext();
  }

  void seekBackward() {
    if (currentPath.value.isEmpty) {
      return;
    }
    final position = player.state.position;
    final newPosition = position - const Duration(seconds: 5);
    player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
    _showSeekFeedback('-5s');
  }

  void seekForward() {
    if (currentPath.value.isEmpty) {
      return;
    }
    final position = player.state.position;
    final duration = player.state.duration;
    final newPosition = position + const Duration(seconds: 5);
    player.seek(newPosition > duration ? duration : newPosition);
    _showSeekFeedback('+5s');
  }

  void _showSeekFeedback(String text) {
    seekFeedback.value = text;
    showSeekFeedback.value = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      showSeekFeedback.value = false;
    });
  }

  void saveMemoryPoint() {
    if (currentPath.value.isEmpty) {
      return;
    }
    final position = player.state.position;
    final ms = position.inMilliseconds;
    SpUtil.putInt(_memoryKeyForPath(currentPath.value), ms);
    memoryPointMs.value = ms;
    Utils.showToastMsg('记忆点已记录 ${_formatDuration(position)}');
  }

  void _loadMemoryPoint(String path) {
    if (path.isEmpty) {
      return;
    }
    final saved = SpUtil.getInt(_memoryKeyForPath(path)) ?? 0;
    memoryPointMs.value = saved;
  }

  String _memoryKeyForPath(String path) {
    return 'video_memory_point_${Uri.encodeComponent(path)}';
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    }
    return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  void showPlaylistSheet() {
    if (playlist.isEmpty) {
      return;
    }
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        color: Colors.black.withOpacity(0.9),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: playlistSheetScrollController,
                  itemExtent: 56,
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final name = playlist[index].path.split('/').last;
                    return ListTile(
                      title: Obx(
                        () => Text(
                          name,
                          style: TextStyle(
                            color: (index == currentIndex.value)
                                ? Colors.amber
                                : Colors.white,
                          ),
                        ),
                      ),
                      onTap: () {
                        playIndex(index);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    _scrollToCurrent(playlistSheetScrollController);
  }

  void togglePlaylistPanel() {
    if (showPlaylist.value) {
      showPlaylist.value = false;
      return;
    }
    showPlaylist.value = true;
    _scrollToCurrent(playlistScrollController);
  }

  void _scrollToCurrent(ScrollController controller) {
    if (!controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrent(controller);
      });
      return;
    }
    final index = currentIndex.value;
    if (index < 0 || index >= playlist.length) {
      return;
    }
    const itemExtent = 56.0;
    final offset = itemExtent * index;
    controller.jumpTo(
      offset.clamp(
        controller.position.minScrollExtent,
        controller.position.maxScrollExtent,
      ),
    );
  }

  // 下拉刷新、上拉加载的示例
  /*
    getCommissionRecord({bool isRefresh = true}) async {
      if (isRefresh) {
        currentPage = 1;
      }
      await LRequest.instance.request<InviteRecordResponseDto>(
          url: NetConstant.HOST +
              "/user/invite/list?pageNum=$currentPage",
          t: InviteRecordResponseDto(),
          requestType: RequestType.GET,
          errorBack: (errorCode, errorMsg, expMsg) {
            refreshController.refreshFailed();
            Utils.showToastMsg("获取列表失败：${errorCode == -1 ? expMsg : errorMsg}");
          },
          isShowLoading: false,
          onSuccess: (result) {
            var model = result.value;
            if (model == null || model.list == null) {
              refreshController.refreshCompleted();
              refreshController.loadComplete();
              return;
            }
            if (isRefresh) {
              inviteProductList.clear();
              currentPage++;
            } else {
              currentPage++;
            }
            inviteProductList.addAll(model.list!);
            refreshController.refreshCompleted();
            refreshController.loadComplete();

            if ((model.count ?? 0) <= (inviteProductList.length)) {
              refreshController.loadNoData();
            }
          });
    }
  */

  void showDeleteConfirmDialog(int index) {
    if (playlist.isEmpty || index < 0 || index >= playlist.length) {
      return;
    }
    final fileName = p.basename(playlist[index].path);

    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文件 "$fileName" 吗？\n\n注意：此操作将永久删除该文件！'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteFileFromPlaylist(index);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteFileFromPlaylist(int index) {
    if (playlist.isEmpty || index < 0 || index >= playlist.length) {
      return;
    }

    final deletedPath = playlist[index].path;
    final wasPlaying = currentPath.value == deletedPath;

    // 删除实际文件
    try {
      final file = File(deletedPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      Utils.showToastMsg('删除文件失败: $e');
      return;
    }

    // 从播放列表中移除
    playlist.removeAt(index);

    // 更新树形播放列表（需要重建整个树形结构）
    if (playlist.isNotEmpty) {
      final rootPath = p.dirname(playlist.first.path);
      _buildTreePlaylist(rootPath);
    } else {
      treePlaylist.clear();
    }

    // 如果删除的是当前正在播放的视频
    if (wasPlaying) {
      if (playlist.isEmpty) {
        // 播放列表为空，停止播放
        player.stop();
        currentPath.value = '';
        currentIndex.value = 0;
      } else {
        // 播放下一个视频
        if (index >= playlist.length) {
          playIndex(0);
        } else {
          playIndex(index);
        }
      }
    } else {
      // 更新当前索引（如果删除的视频在当前播放视频之前）
      if (index < currentIndex.value) {
        currentIndex.value--;
      }
    }

    Utils.showToastMsg('文件已删除');
  }
}
