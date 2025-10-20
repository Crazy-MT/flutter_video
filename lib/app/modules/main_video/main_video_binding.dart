import 'package:get/get.dart';

import 'main_video_controller.dart';

class MainVideoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainVideoController>(
      () => MainVideoController(),
    );
  }
}
