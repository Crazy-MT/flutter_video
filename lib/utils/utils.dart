import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:yueshi_player/app/routes/app_routes.dart';
import 'package:yueshi_player/common/components/confirm_dialog.dart';
import 'package:yueshi_player/utils/log_utils.dart';
import 'package:yueshi_player/utils/platform_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import '../common/colors.dart';

class Utils {
  static showToastMsg(String msg) {
    showToastWidget(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: ColorsApp.text_dark,
        ),
        margin: const EdgeInsets.only(left: 53, right: 53),
        padding: const EdgeInsets.all(15),
        child: Text(
          msg,
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
          strutStyle: const StrutStyle(
            forceStrutHeight: true,
            leading: 0.4,
          ),
        ),
      ),
      position: const ToastPosition(align: Alignment.bottomCenter, offset: -120),
      dismissOtherToast: true,
      duration: const Duration(seconds: 2),
    );
  }

}
