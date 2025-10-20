enum RoomTypeEnum {
  PRACTICE(0),
  DOUYIN(1),
  KUAISHOU(2),
  SHIPINHAO(3);

  final int type;

  const RoomTypeEnum(this.type);

  int getType() {
    return type;
  }

/*
  static RoomTypeEnum fromType(int type) {
    switch (type) {
      case 0:
        return RoomTypeEnum.PRACTICE;
      case 1:
        return RoomTypeEnum.DOUYIN;
      case 2:
        return RoomTypeEnum.KUAISHOU;
      case 3:
        return RoomTypeEnum.SHIPINHAO;
      default:
        return RoomTypeEnum.DOUYIN;
    }
  }
*/

  static String fromType(int type) {
    switch (type) {
      case 1:
        return "抖音";
      case 2:
        return '快手';
    }
    return "";
  }
}