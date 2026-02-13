import 'dart:io';
import 'dart:math';

import 'package:flutter_video_stable/common/common.dart';
import 'package:flutter_video_stable/utils/log_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_video_stable/common/components/status_page/status_page.dart';
import 'package:flutter_video_stable/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sp_util/sp_util.dart';
// import 'package:uri_to_file/uri_to_file.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MainVideoController extends GetxController {
  final pageName = 'MainVideo'.obs;
  final errorMsg = "".obs;
  final pageStatus = FTStatusPageType.loading.obs;

  //ScrollController scrollController = ScrollController();
  //RxList<InviteRecordDto?> inviteProductList = RxList<InviteRecordDto?>();
  final RefreshController refreshController = new RefreshController();

  int currentPage = 0;

  static const platform = MethodChannel('com.bomanyi.ai/channel');
  var currentPath = ''.obs;
  var playlist = [].obs;

  var currentIndex = 0.obs;
  var showPlaylist = false.obs; // 控制是否显示列表
  var memoryPointMs = 0.obs;
  final playlistScrollController = ScrollController();
  final playlistSheetScrollController = ScrollController();

  late final player = Player();
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
    // requestStoragePermission();
  }

  Future<void> requestStoragePermission() async {
    if(!Platform.isAndroid) {
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
      currentPath.value = call.arguments as String;
      print("📥 收到视频 URI: ${currentPath.value}");
      playFile(currentPath.value);
    }
  }

  void playFile(String path) async {
    lLog('MainVideoController.playFile ${path} ');
    await player.open(Media(path));
    _loadMemoryPoint(path);
  }

  void pickFolder() async {
    lLog('MainVideoController.pickFolder } ');
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath != null) {
      print('选中的文件夹: $folderPath');

      final dir = Directory(folderPath);
      playlist.value = dir.listSync(recursive: true);

      playlist.sort((a, b) => a.path.compareTo(b.path));
      // showPlaylist.value = true;
      playIndex(Random().nextInt(playlist.length));
    }
  }

  void setPageName(String newName) {
    pageName.value = newName;
  }

  @override
  void onClose() {
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
              child: Obx(() => ListView.builder(
                    controller: playlistSheetScrollController,
                    itemExtent: 56,
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final name = playlist[index].path.split('/').last;
                      return ListTile(
                        title: Obx(() => Text(
                              name,
                              style: TextStyle(
                                color: (index == currentIndex.value)
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            )),
                        onTap: () {
                          playIndex(index);
                          Get.back();
                        },
                      );
                    },
                  )),
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

}
