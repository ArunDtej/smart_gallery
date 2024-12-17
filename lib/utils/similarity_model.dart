import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
// import 'package:smart_gallery/main.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;

class SimilarityModel {
  Interpreter? _interpreter;
  IsolateInterpreter? isolateInterpreter;
  String progress = '0';

  Future<void> initModel() async {
    var interpreterOptions = InterpreterOptions()..useNnApiForAndroid = true;

    _interpreter = await Interpreter.fromAsset(
      'assets/models/cosine_similarity_model.tflite',
      options: interpreterOptions,
    );
  }

  Future<List<AssetEntity>> searchSimilar(
      AssetPathEntity folderAsset, List<double> searchFor) async {
    var size = 100;
    int page = 0;
    List<Float32List> allImagesEmbeddings = [];
    Map rawEmbeddings =
        HiveService.instance.getEmbeddingsBox().get('rawEmbeddings');
    var embeddedKeys = rawEmbeddings.keys;

    while (true) {
      List<AssetEntity> images =
          await folderAsset.getAssetListPaged(page: page, size: size);

      if (images.isEmpty) {
        break;
      }

      for (int i = 0; i < images.length; i++) {
        String? path = '${images[i].relativePath}${images[i].title}';

        if (embeddedKeys.contains(path)) {
          List<double> rawEmbedding = List<double>.from(rawEmbeddings[path]);
          allImagesEmbeddings.add(Float32List.fromList(rawEmbedding));
        }
      }

      page++;
    }

    List<dynamic> outputs = await predictBatch(allImagesEmbeddings, searchFor);

    List<int> sortedArgs = argsort(outputs).reversed.toList();

    return [];
  }

  Future<List<dynamic>> predictBatch(
      List<Float32List> batchInput, List<double> searchFor) async {
    List<List<List<double>>> inputList = [];

    for (var image in batchInput) {
      List<double> imageEmbedding = List<double>.from(image);
      List<List<double>> combinedInput = [imageEmbedding, searchFor];

      inputList.add(combinedInput);
    }

    List<Object> inputs = inputList;

    List<dynamic> outputs =
        List<double>.filled(inputs.length, 0).reshape([inputs.length]);

    _interpreter?.run(inputs, outputs);

    return outputs;
  }

  List<int> argsort(List<dynamic> list) {
    List<int> indices = List<int>.generate(list.length, (index) => index);
    indices.sort((a, b) => list[a].compareTo(list[b]));
    return indices;
  }
}
