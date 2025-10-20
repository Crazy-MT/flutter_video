import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter_video_stable/app/routes/app_routes.dart';
import 'package:flutter_video_stable/common/components/confirm_dialog.dart';
import 'package:flutter_video_stable/common/components/resource_category.dart';
import 'package:flutter_video_stable/utils/log_utils.dart';
import 'package:flutter_video_stable/utils/platform_utils.dart';
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

  Future<Uint8List?> capturePng(GlobalKey globalKey) async {
    RenderObject? obj = globalKey.currentContext?.findRenderObject();
    if (obj is RenderRepaintBoundary) {
      double dpr = ui.window.devicePixelRatio; // 获取当前设备的像素比
      var image = await obj.toImage(pixelRatio: dpr);
      ByteData? _byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? sourceBytes = _byteData?.buffer.asUint8List();
      if (sourceBytes != null) {
        return sourceBytes;
      }
    }
    return null;
  }

  saveImageToFile(GlobalKey repaintWidgetKey) async {
    Uint8List? sourceBytes = await capturePng(repaintWidgetKey);

    if (sourceBytes != null) {
      if (PlatformUtils.isWeb) {
        const String fileName = 'invite.png';
        final String? path = await getSavePath(suggestedName: fileName);
        if (path == null) {
          return;
        }

        final XFile imageFile = XFile.fromData(sourceBytes, mimeType: "file/image", name: fileName);
        await imageFile.saveTo(path);
        Utils.showToastMsg('保存海报成功');
        return;
      }

      Permission filePermission = PlatformUtils.isIOS ? Permission.photos : Permission.storage;
      // lLog('MTMTMT Utils.saveImageToFile ${filePermission} ');
      var status = await filePermission.status;
      if (!status.isGranted) {
        Map<Permission, PermissionStatus> statuses = await [filePermission].request();
        // lLog(
        //     'MTMTMT Utils.saveImageToFile ${statuses} ${statuses['Permission.photos']}');
        if (statuses[Permission.photos] == PermissionStatus.limited ||
            statuses[Permission.photos] == PermissionStatus.denied) {
          showConfirmDialog(
              title: '需要您的相册权限，请在设置里打开',
              onConfirm: () {
                openAppSettings();
              });
          return;
        }
        saveImageToFile(repaintWidgetKey);
      }
      if (status.isGranted) {
        // final result =
        //     await ImageGallerySaver.saveImage(sourceBytes, quality: 80);
        // if (result["isSuccess"]) {
        //   Utils.showToastMsg('保存成功');
        // } else {
        //   Utils.showToastMsg('保存失败');
        // }
      }
      if (status.isDenied) {
        Utils.showToastMsg('请开启相册权限');
      }
    }
  }

  Future<void> checkUserInfo(String page) async {
    if (page == RoutesID.HOME_PAGE) {
      return;
    }

    if (Get.arguments == null || Get.arguments["from"] == null) {
      Get.back();
    } else {
      Get.offAllNamed(RoutesID.MAIN_TAB_PAGE);
    }
/*
    if (userHelper.userInfo.value == null) {
      return;
    }
    if ((userHelper.userInfo.value?.checkRes ?? 0) != 1) {
      bool result = await Get.toNamed(RoutesID.AUTH_CHECK_PAGE,
          arguments: {'from': page});
      if (!result) {
        return;
      }
    }

    if ((userHelper.userInfo.value?.hasPaymentMethod ?? 0) == 0) {
      await Get.toNamed(RoutesID.COLLECTION_SETTINGS_PAGE,
          arguments: {'from': page});

      if ((userHelper.userInfo.value?.hasPaymentMethod ?? 0) == 0) {
        return;
      }
    }

    if ((userHelper.userInfo.value?.hasAddress ?? 0) == 0) {
      await Get.toNamed(RoutesID.ADDRESS_MANAGE_PAGE,
          arguments: {'from': page});
      if ((userHelper.userInfo.value?.hasAddress ?? 0) == 0) {
        return;
      }
    }

    if (page == RoutesID.HOME_PAGE) {
      return;
    }

    if (Get.arguments == null || Get.arguments["from"] == null) {
      Get.back();
    } else {
      Get.offAllNamed(RoutesID.MAIN_TAB_PAGE);
    }
*/
  }

}

String formatPriceToString(int? priceInCents) {
  if (priceInCents == null) return '';
  int dollars = priceInCents ~/ 100;
  int cents = priceInCents % 100;
  return "$dollars.${cents.toString().padLeft(2, '0')}";
}

bool supportAudio(String path) {
  String lowerCasePath = path.toLowerCase();
  const supportedExtensions = [
    '.wav',
    '.mp3',
    '.aac',
    '.m4a',
    '.ogg',
  ];
  return supportedExtensions.any((ext) => lowerCasePath.endsWith(ext));
}

bool supportVideo(String path) {
  String lowerCasePath = path.toLowerCase();
  const supportedExtensions = [
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.wmv',
    '.flv',
    '.mpeg',
  ];
  return supportedExtensions.any((ext) => lowerCasePath.endsWith(ext));
}

bool checkVideoStatus(String path) {
  // 最好将逻辑封装在函数中
  const int compressionTimeLimitSeconds = 3 * 60; // 180 秒
  if (path.startsWith("https://") && path.contains("/compress/")) {
    int lastSlashIndex = path.lastIndexOf('/');
    // 添加检查确保找到了 '/' 并且它不是路径的最后一个字符
    if (lastSlashIndex != -1 && lastSlashIndex < path.length - 1) {
      String fileName = path.substring(lastSlashIndex + 1);
      // 使用 replaceAll 更安全，并移除扩展名
      String timestampString = fileName.replaceAll(".flv", "").replaceAll(".mp4", "");
      // 2. 使用 int.tryParse 处理潜在的解析错误
      int? createTimeMillis = int.tryParse(timestampString);
      if (createTimeMillis != null) {
        // 3. 获取当前时间戳 (毫秒)
        int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
        // 4. 计算时间差 (秒)，使用整数除法 `~/`
        int elapsedSeconds = (currentTimeMillis - createTimeMillis) ~/ 1000;
        if (elapsedSeconds < compressionTimeLimitSeconds) {
          int remainingSeconds = compressionTimeLimitSeconds - elapsedSeconds;
          // 5. 显示 Toast 提示 (需要 fluttertoast 包)
          showToast("该视频正在云端压缩中，请 $remainingSeconds 秒后重试");
          return false; // 6. 提前返回，和 Java 代码行为一致
        }
      } else {
        // 处理无法从文件名解析出时间戳的情况
        print("无法从文件名 '$fileName' 解析时间戳");
        return true;
      }
    } else {
      // 处理路径格式不正确的情况
      print("路径格式不正确，无法提取文件名: '$path'");
      return true;
    }
  }
  // 如果代码执行到这里，说明视频要么不在压缩中，要么已经过了等待时间
  // 可以继续执行后续逻辑...
  print("视频检查通过或路径不匹配压缩模式。");
  return true;
}


/// 判断文件路径是否包含拓展名
bool hasExtension(String filePath) {
  final ext = extension(filePath);
  return ext.isNotEmpty && ext != basename(filePath); // 防止是 . 开头的隐藏文件夹误判
}

bool isEnglishOnly(String str) {
  final regex = RegExp(r'^[a-zA-Z]+$');
  return regex.hasMatch(str);
}

String? getEndTime(String? endTime) {
  // 输入的字符串

  // 将字符串解析为 DateTime 对象
  DateTime dateTime = DateTime.parse(endTime ?? "");

  // 定义 2035 年的某个时间点（如 2035-12-31 23:59:59）
  DateTime year2035End = DateTime(2035, 1, 1, 0, 0, 0);

  // 判断是否大于 2035 年
  bool isAfter2035 = dateTime.isAfter(year2035End);

  if (isAfter2035) {
    return '终身';
  }
  return endTime;
}

Future<String> getLocalIp() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );

  // // 1. 过滤虚拟接口（VPN/虚拟机等）[7](@ref)
  // final filteredInterfaces = interfaces.where((interface) {
  //   return !['tun', 'ppp', 'vmnet', 'veth'].any((prefix) =>
  //       interface.name.startsWith(prefix));
  // }).toList();
  //
  // // 2. 接口排序：优先物理接口（WiFi/有线）[7](@ref)
  // filteredInterfaces.sort((a, b) {
  //   if (a.name.startsWith('wlan') || a.name.startsWith('eth')) return -1;
  //   return 1;
  // });

  // 3. 私有IP分类与优先级排序
  final List<InternetAddress> privateIps = [];

  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (_isPrivateIP(addr)) {
        privateIps.add(addr);
      }
    }
  }

  // 4. 按优先级排序：192 > 172 > 10
  privateIps.sort((a, b) {
    final aValue = _getIpPriority(a.address);
    final bValue = _getIpPriority(b.address);
    return aValue.compareTo(bValue);
  });

  // 5. 返回最高优先级IP
  if (privateIps.isNotEmpty) {
    return privateIps.first.address;
  }

  // 6. 兜底逻辑：返回首个非回环地址
  for (var interface in interfaces) {
    if (interface.addresses.isNotEmpty) {
      return interface.addresses.first.address;
    }
  }

  return '';
}

// --- 工具函数 ---
// 计算IP优先级（数值越小优先级越高）
int _getIpPriority(String ip) {
  final parts = ip.split('.').map(int.parse).toList();
  if (parts[0] == 192 && parts[1] == 168) return 1; // 最高优先级
  if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return 2;
  if (parts[0] == 10) return 3; // 最低优先级
  return 4; // 其他私有IP（理论上不会进入此分支）
}

// 检查是否为标准私有IP
bool _isPrivateIP(InternetAddress addr) {
  final parts = addr.address.split('.').map(int.parse).toList();
  if (parts.length != 4) return false;
  if (parts[0] == 10) return true;
  if (parts[0] == 192 && parts[1] == 168) return true;
  if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
  return false;
}


