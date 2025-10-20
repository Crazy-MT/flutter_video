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
  void onClose() {}

  playIndex(int index) {
    currentIndex.value = index;
    var path = playlist[index].path;
    currentPath.value = path;
    playFile(path);
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
