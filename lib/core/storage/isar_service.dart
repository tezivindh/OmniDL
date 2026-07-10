import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:omnidl/features/downloader/data/models/download_task_model.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  late final Isar _isar;

  Isar get isar => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [DownloadTaskModelSchema],
      directory: dir.path,
    );
  }
}
