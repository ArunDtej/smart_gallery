import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/main.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
    final isolateInterpreter =
        await IsolateInterpreter.create(address: _interpreter!.address);
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
      // Get a page of images from the folder
      List<AssetEntity> images =
          await folderAsset.getAssetListPaged(page: page, size: size);

      if (images.isEmpty) {
        break; // Stop if no more images
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

    print("Total embeddings: ${allImagesEmbeddings.length}, "
        "Embedding size: ${allImagesEmbeddings.isNotEmpty ? allImagesEmbeddings[0].length : 0}");

    predictBatch(allImagesEmbeddings, searchFor);

    return [];
  }

  Future<List<List<double>>> predictBatch(
      List<Float32List> batchInput, List<double> searchFor) async {
    List<List<List<double>>> inputList = [];

    print(searchFor);

    print(searchFor.shape);
    for (var image in batchInput) {
      List<double> imageEmbedding = List<double>.from(image);
      List<List<double>> combinedInput = [imageEmbedding, searchFor];

      inputList.add(combinedInput);
    }

    List<Object> inputs = inputList;

    Map<int, Object> outputs = {};
    for (int i = 0; i < batchInput.length; i++) {
      outputs[i] = List<double>.filled(1, 0.0);
    }

    print('Input shape: [${inputs.length}, ${inputs.shape}]');

    await isolateInterpreter?.runForMultipleInputs(inputs, outputs);

    List<List<double>> results = [];
    for (int i = 0; i < batchInput.length; i++) {
      results.add(List<double>.from(outputs[i] as List<double>));
    }

    print('Output shape: [${results.length}, ${results[0].length}]');

    print(outputs);

    return results;
  }
}
