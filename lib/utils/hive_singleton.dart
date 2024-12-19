import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_gallery/utils/models.dart';
import 'package:smart_gallery/utils/similarity_model.dart';

class HiveService {
  HiveService._privateConstructor();
  static final HiveService instance = HiveService._privateConstructor();

  late Box EmbeddingsBox;
  Model model = Model();
  SimilarityModel similarityModel = SimilarityModel();
  bool isModelRunning = false;
  bool isSimilarityModelRunning = false;
  int resolutionLimit = 18000;
  double generateEmbeddingsProgress = 0.0;
  bool isBroken = false;
  late List<int> searchIndices;

  Future<void> init() async {
    await Hive.initFlutter();
    EmbeddingsBox = await Hive.openBox('EmbeddingsBox');
    if (EmbeddingsBox.get('rawEmbeddings') == null) {
      EmbeddingsBox.put('rawEmbeddings', {});
    }
    model.initModel();
    similarityModel.initModel();
  }

  Box getEmbeddingsBox() {
    return EmbeddingsBox;
  }

  Model getModel() {
    return model;
  }
}
