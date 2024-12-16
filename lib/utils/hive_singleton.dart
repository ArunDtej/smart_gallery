import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._privateConstructor();
  static final HiveService instance = HiveService._privateConstructor();

  late Box rawEmbeddingBox;

  Future<void> init() async {
    await Hive.initFlutter();
    rawEmbeddingBox = await Hive.openBox('rawEmbeddingBox');
  }

  dynamic getRawEmbeddingBox() {
    return rawEmbeddingBox;
  }
}
