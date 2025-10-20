import 'dart:io';

import 'package:flutter_video_stable/common/colors.dart';
import 'package:flutter_video_stable/utils/platform_utils.dart';
import 'package:flutter_video_stable/utils/scroll_behavior.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_video_stable/utils/platform_utils.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  if (PlatformUtils.isAndroid) {
    SystemUiOverlayStyle style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        ///这是设置状态栏的图标和字体的颜色
        ///Brightness.light  一般都是显示为白色
        ///Brightness.dark 一般都是显示为黑色
        statusBarIconBrightness: Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  WidgetsFlutterBinding.ensureInitialized();


  MediaKit.ensureInitialized();

  runApp(App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: MouseDragBehavior(),
      child: ScreenUtilInit(
        // scaleByHeight: PlatformUtils.isWeb,
        designSize: const Size(375, 812),
        builder: (context, widget) {
          return OKToast(
            dismissOtherOnShow: true,
            child: GetMaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                RefreshLocalizations.delegate
              ],
              supportedLocales: [
                Locale('zh', ''),
                Locale('en', ''),
              ],
              theme: ThemeData(
                fontFamily: 'TabTitle',
                textTheme: Theme.of(context).textTheme.apply(fontFamily: 'TabTitle'),
                splashColor: Colors.transparent,
                // 点击时的高亮效果设置为透明
                highlightColor: Colors.transparent,
                // 长按时的扩散效果设置为透明
                scaffoldBackgroundColor: Colors.white,
                primaryColor: ColorsApp.teal_200,
                buttonTheme: ButtonThemeData(buttonColor: ColorsApp.teal_200),
                textSelectionTheme: TextSelectionThemeData(
                    cursorColor: ColorsApp.teal_200,
                    selectionColor: ColorsApp.teal_200,
                    selectionHandleColor: ColorsApp.teal_200),
                sliderTheme: SliderThemeData(
                  thumbColor: ColorsApp.teal_200,
                  // 滑块颜色
                  activeTrackColor: ColorsApp.teal_200,
                  // 激活部分的轨道颜色
                  inactiveTrackColor: ColorsApp.teal_200,
                  // 未激活部分的轨道颜色
                  overlayColor: ColorsApp.teal_200.withOpacity(0.2),
                  // 滑块按下时的涟漪效果颜色
                  valueIndicatorColor: ColorsApp.teal_200, // 显示数值提示框的颜色
                ),
                inputDecorationTheme: InputDecorationTheme(
                  // 未选中时的下划线颜色
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorsApp.teal_200),
                  ),
                  // 选中时的下划线颜色
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorsApp.teal_200),
                  ),
                  // 禁用时的下划线颜色
                  disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorsApp.teal_200.withOpacity(0.5)),
                  ),
                  // 有错误时的下划线颜色
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorsApp.teal_200),
                  ),
                  // 选中且有错误时的下划线颜色
                  focusedErrorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorsApp.teal_200),
                  ),
                ),
                progressIndicatorTheme: ProgressIndicatorThemeData(
                  color: ColorsApp.teal_200, // 主要颜色（圆形或线性加载的前景色）
                  linearTrackColor: Colors.grey.shade300, // 线性加载背景轨道颜色
                  circularTrackColor: Colors.grey.withOpacity(0.2), // 圆形加载背景轨道颜色
                ),
              ),
              debugShowCheckedModeBanner: false,
              builder: EasyLoading.init(
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    child: GestureDetector(
                      onTap: () {
                        hideKeyboard(context);
                      },
                      child: child,
                    ),
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  );
                },
              ),
              defaultTransition: Transition.rightToLeft,
              title: "播放",
              initialRoute: RoutesID.MAIN_VIDEO_PAGE,
              getPages: AppPages.routes,
            ),
          );
        },
      ),
    );
  }
}

void hideKeyboard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    FocusManager.instance.primaryFocus!.unfocus();
  }
}
