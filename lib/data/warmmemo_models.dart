import 'package:isar/isar.dart';

part 'warmmemo_models.g.dart';

/// 紀念頁草稿 – 對應 TAB「簡易紀念頁」
@collection
class MemorialPageDraft {
  MemorialPageDraft();

  /// 單一使用者目前只需要 1 筆草稿，可用固定 id 紀錄
  Id id = 1;

  String? name;
  String? nickname;
  String? motto;
  String? bio;
  String? highlights;
  String? willNote;

  DateTime updatedAt = DateTime.now();
}

/// 數位訃聞草稿 – 對應 TAB「數位訃聞」
@collection
class ObituaryDraft {
  ObituaryDraft();

  Id id = 1;

  String? deceasedName;
  String? relationship;
  String? location;
  String? serviceDate;
  String? tone; // 溫和正式／宗教色彩／極簡通知
  String? customNote;

  DateTime updatedAt = DateTime.now();
}

