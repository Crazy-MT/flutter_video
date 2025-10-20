import 'package:media_kit_video/media_kit_video.dart';

import 'main_video_controller.dart';
import 'package:flutter_video_stable/common/components/status_page/status_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_video_stable/app/routes/app_routes.dart';
import 'package:flutter_video_stable/common/colors.dart';
import 'package:flutter_video_stable/common/components/common_app_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainVideoPage extends GetView<MainVideoController> {
  const MainVideoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            return Stack(
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
                          : Video(
                              controller: controller.controller,
                            ),
                    )),
                // ✅ 半透明播放列表（覆盖在右边）
                Obx(() => Visibility(
                    visible: controller.showPlaylist.value,
                    child: Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: 200,
                      // 固定宽度
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          children: [
                            // 顶部关闭按钮
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => controller.showPlaylist.value = false,
                              ),
                            ),

                            Expanded(
                              child: Obx(() => ListView.builder(
                                    itemCount: controller.playlist.length,
                                    itemBuilder: (context, index) {
                                      final name = controller.playlist[index].path.split('/').last;
                                      return ListTile(
                                        title: Obx(() => Text(
                                              name,
                                              style: TextStyle(
                                                color: (index == controller.currentIndex.value)
                                                    ? Colors.amber
                                                    : Colors.white,
                                              ),
                                            )),
                                        onTap: () => controller.playIndex(index),
                                        onLongPress: () => controller.showPlaylist.value =
                                            !(controller.showPlaylist.value),
                                      );
                                    },
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ))),

                // ✅ 右下角呼出播放列表按钮
                Positioned(
                  right: 20,
                  top: Get.height / 2,
                  child: FloatingActionButton(
                    backgroundColor: Colors.black.withOpacity(0.2),
                    child: const Icon(Icons.list, color: Colors.white),
                    onPressed: () =>
                        controller.showPlaylist.value = !(controller.showPlaylist.value),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
