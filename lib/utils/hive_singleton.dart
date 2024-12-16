import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_gallery/utils/models.dart';

class HiveService {
  HiveService._privateConstructor();
  static final HiveService instance = HiveService._privateConstructor();

  late Box EmbeddingsBox;
  Model model = Model();
  bool isModelRunning = false;

  Future<void> init() async {
    
    await Hive.initFlutter();
    EmbeddingsBox = await Hive.openBox('EmbeddingsBox');
    if (EmbeddingsBox.get('rawEmbeddings') == null) {
      EmbeddingsBox.put('rawEmbeddings', {});
    }
    model.initModel();
  }

  Box getEmbeddingsBox() {
    return EmbeddingsBox;
  }

  Model getModel() {
    return model;
  }
}
