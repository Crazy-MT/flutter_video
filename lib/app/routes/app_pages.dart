import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/main_video/main_video_binding.dart';
import '../modules/main_video/main_video_page.dart';

class AppPages {
  AppPages._();

  static final routes = _routes;

  static final List<GetPage> _routes = [
    // main_video
    GetPage(
      name: RoutesID.MAIN_VIDEO_PAGE,
      page: () => const MainVideoPage(),
      binding: MainVideoBinding(),
    ),
  ];
}
