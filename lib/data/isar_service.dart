import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'warmmemo_models.dart';

/// 單例 Isar 服務：負責開啟資料庫與提供 Collection 存取
class IsarService {
  IsarService._internal();

  static final IsarService instance = IsarService._internal();

  Isar? _isar;

  Future<Isar> get db async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [MemorialPageDraftSchema, ObituaryDraftSchema],
      directory: dir.path,
    );
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}

