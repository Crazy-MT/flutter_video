import 'dart:convert';

import 'package:flutter_video_stable/common/C.dart';
import 'package:sp_util/sp_util.dart';

class SpHelper {
  static const String SP_CHAT_POSITION_X = 'sp_chat_position_x';
  static const String SP_CHAT_POSITION_Y = 'sp_chat_position_y';
  static const String SP_CHAT_HEIGHT = 'chatHeight';
  static const String SP_MUSIC_HEIGHT = 'sp_music_height';
  static const String SP_CHAT_WIDTH = 'sp_chat_width';
  static const String SP_MUSIC_WIDTH = 'sp_music_width';

  static const String SP_TELE_HEIGHT = 'sp_tele_height';

  static double getChatPositionX(double defValue) {
    return SpUtil.getDouble(SP_CHAT_POSITION_X, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setChatPositionX(double positionX) {
    return SpUtil.putDouble(SP_CHAT_POSITION_X, positionX);
  }

  static double getChatPositionY(double defValue) {
    return SpUtil.getDouble(SP_CHAT_POSITION_Y, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setChatPositionY(double positionY) {
    return SpUtil.putDouble(SP_CHAT_POSITION_Y, positionY);
  }

  static double getChatHeight(double defValue) {
    return SpUtil.getDouble(SP_CHAT_HEIGHT, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setChatHeight(double chatHeight) {
    return SpUtil.putDouble(SP_CHAT_HEIGHT, chatHeight);
  }

  static double getMusicHeight(double defValue) {
    return SpUtil.getDouble(SP_MUSIC_HEIGHT, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setMusicHeight(double chatHeight) {
    return SpUtil.putDouble(SP_MUSIC_HEIGHT, chatHeight);
  }

  static double getMusicWidth(double defValue) {
    return SpUtil.getDouble(SP_MUSIC_WIDTH, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setMusicWidth(double chatWidth) {
    return SpUtil.putDouble(SP_MUSIC_WIDTH, chatWidth);
  }

  static Future<bool>? setChatWidth(double chatWidth) {
    return SpUtil.putDouble(SP_CHAT_WIDTH, chatWidth);
  }

  static double getChatWidth(double defValue) {
    return SpUtil.getDouble(SP_CHAT_WIDTH, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setTeleprompterHeight(double chatWidth) {
    return SpUtil.putDouble(SP_TELE_HEIGHT, chatWidth);
  }

  static double getTeleprompterHeight(double defValue) {
    return SpUtil.getDouble(SP_TELE_HEIGHT, defValue: defValue) ?? defValue;
  }

  /*static bool getAIReply(bool defValue) {
    return SpUtil.getBool(SpConst.SP_AI_REPLY, defValue: defValue) ?? defValue;
  }

  static Future<bool>? setAIReply(bool aiReply) {
    return SpUtil.putBool(SpConst.SP_AI_REPLY, aiReply);
  }*/


}
