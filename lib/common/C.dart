// ignore_for_file: constant_identifier_names

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class C {
  static const String USER_TOKEN = "user_token";
  static const String USER_INFO = "user_info";
  static const String SHOW_DIALOG = "show_dialog";
  static const String USER_SCRIPT_LAST_TIME = "user_script_last_time";
  static const String ACTIVE_ROOM_ID = "activeRoomId";
  static const String ACTIVE_ROOM_TYPE = "activeRoomType";
  static const String ACTIVE_ROOM_NAME = "activeRoomName";

  static const String USER_KEYWORD_LAST_TIME_V1 = 'user_keyword_last_time_v1';
  static const String SP_AI_REPLY = 'sp_ai_reply';

  static const String SHOW_ENTER = "show_enter";
  static const String SHOW_LIKE = "show_like";
  static const String SHOW_SOCIAL = "show_social";
  static const String SHOW_GIFT = "show_gift";
  static const String SHOW_CHAT = "show_chat";
  static const String AI_HIGH_QUALITY = "ai_high_quality";
  static const String KUAISHOU_GIFT = "kuaishou_gift";
  static const String SHIPINHAO_GIFT = "shipinhao_gift";
  static const String KUAISHOU_GIFT_TIME = "kuaishou_gift_time";
  static const String SHIPINHAO_GIFT_TIME = "shipinhao_gift_time";

  static const String DOUYIN_GIFT = "douyin_gift";
  static const String DOUYIN_GIFT_TIME = "douyin_gift_time";
  static const String KUAISHOU_WSS = "kuaishou_wss";
  static const String DOUYIN_COOKIE = "douyin_cookie";
  static const String HOST = "host";
  static const String CACHE_SERVER = "cache_server";
  static const String CHOOSE_MIC = "choose_mic";
  static const String CHOOSE_SOUND = "choose_sound";
  static const String CHOOSE_SOUND_DESC = "choose_sound_desc";

  static const String IS_LIVED = "is_lived";
  static const String OVERLAY_TEXT_SIZE = "overlay_text_size";
  static const String OVERLAY_TEXT_COLOR = "overlay_text_color";
  static const String OVERLAY_OPACITY = "overlay_opacity";

  static const String JSON = "json";
  static const String SHOULD_BACK_UP_DB = "should_back_up_db";

  static var keywordHeight = 40.w;
  static var keywordCount = ((Get.height - Get.bottomBarHeight) / C.keywordHeight).toInt() - 1;

  static const String CHOOSE_KEYBOARD = "choose_keyboard";
  static const String HOTKEY_SWITCH = "hotkey_switch";
  static const String HOTKEY_ESC = "hotkey_esc";
  static const String HOTKEY_ENABLE = "hotkey_enable";

  static const String MATCH_INDEX_KEY = 'matchIndex';
  static const String MATCH_LENGTH_KEY = 'matchLength';
  static const String LAST_KNOWN_MATCH_END_KEY = 'lastKnownMatchEnd';
  static const String SCROLL_OFFSET = 'scroll_offset';

  static const String BOTTOM_SAVE = 'bottomSave';
  static const String BOTTOM_RESTORE = 'bottomRestore';
  static const String BOTTOM_CLEAR = 'bottomClear';

  static const String TOP_SAVE = 'topSave';
  static const String TOP_RESTORE = 'topRestore';
  static const String TOP_CLEAR = 'topClear';

  static const String KEY_MINUS = 'keyMinus';
  static const String KEY_EQUAL = 'keyEqual';
  static const String KEY_UP = 'keyUp';

  static List<String> keyList = [
    "铺垫",
    "拉票",
    "过加成",
    "打加成",
    "偷塔",
    "守塔",
    "谢榜",
    // "总榜拉票",
    // "加成拉票",
    // "守塔拉票",
    // "票多拉票",
    // "票少拉票",
    // "PK互怼",
    // "PK输了",
    // "PK赢了"
  ];
}
